import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace_models.dart';
import '../models/history_models.dart';
import 'package:flutter/material.dart'; // Provides Color, debugPrint, ValueNotifier, etc.

import '../models/invoice.dart'; // Import Invoice model
import 'dart:convert'; // For jsonEncode/Decode
import 'package:shared_preferences/shared_preferences.dart';

class MarketplaceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Local Storage for Guest Mode (Static to persist across instances) ---
  // --- Local Storage for Guest Mode (Static to persist across instances) ---
  static List<Invoice> _localInvoices = [];
  static List<DashboardActivity> _localActivity = [];
  static bool _initialized = false;

  MarketplaceService() {
    _initLocal();
  }

  Future<void> _initLocal() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final invString = prefs.getString('local_invoices');
      if (invString != null) {
        final List<dynamic> json = jsonDecode(invString);
        _localInvoices = json.map((e) => Invoice.fromJson(e)).toList();
      }

      final actString = prefs.getString('local_activity');
      if (actString != null) {
        final List<dynamic> json = jsonDecode(actString);
        _localActivity = json.map((e) => DashboardActivity.fromJson(e)).toList();
      }
      _initialized = true;
      updateNotifier.value++; // Trigger UI update after load
    } catch (e) {
      debugPrint('Error loading local data: $e');
    }
  }

  Future<void> _saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final invString = jsonEncode(_localInvoices.map((e) => e.toJson()).toList());
      await prefs.setString('local_invoices', invString);

      final actString = jsonEncode(_localActivity.map((e) => e.toJson()).toList());
      await prefs.setString('local_activity', actString);
    } catch (e) {
      debugPrint('Error saving local data: $e');
    }
  }

  // --- Real-time Updates ---
  static final ValueNotifier<int> updateNotifier = ValueNotifier(0);

  // --- Dashboard Stats ---

  Future<Map<String, dynamic>> getDashboardStats() async {
    final sellerId = _supabase.auth.currentUser?.id;
    
    // GUEST MODE / OFFLINE
    if (sellerId == null) {
      int totalShelves = 0;

      
      for (var inv in _localInvoices) {
        if (inv.paid && inv.type == InvoiceType.rental && inv.metaData != null) {
          totalShelves += (inv.metaData!['shelves'] as int? ?? 0);
        }
      }
      
      return {
        'shelves': totalShelves,
        'items': 0, // Not tracking local inventory count deeply yet
        'pendingOrders': 0,
        'totalValue': 0.0,
        'activeRentals': [], // detailed list optional for now
      };
    }

    // AUTHENTICATED MODE
    try {
      // 1. Shelves (Active Subscriptions)
      final subsResponse = await _supabase
          .from('sme_subscriptions')
          .select('*, warehouses(name)')
          .eq('seller_id', sellerId)
          .eq('is_active', true);
      
      final activeRentals = (subsResponse as List).map((e) => {
        'warehouse': e['warehouses']['name'] ?? 'Unknown',
        'shelves': e['shelves_count'],
        'end_date': e['end_date']
      }).toList();

      int totalShelves = 0;
      for (var sub in activeRentals) {
        totalShelves += (sub['shelves'] as int);
      }

      // 2. Items & Total Value
      final inventoryResponse = await _supabase
          .from('sme_inventory')
          .select('quantity, sme_products(price)')
          .eq('seller_id', sellerId)
          .eq('status', 'in_stock');
      
      int totalItems = 0;
      double totalValue = 0.0;
      
      for (var item in (inventoryResponse as List)) {
        final qty = item['quantity'] as int;
        totalItems += qty;
        final price = (item['sme_products']['price'] as num).toDouble();
        totalValue += (qty * price);
      }

      // 3. Pending Orders
      final ordersResponse = await _supabase
          .from('sme_orders')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'pending')
          .count(CountOption.exact);
      
      final pendingOrdersCount = ordersResponse.count;

      return {
        'shelves': totalShelves,
        'items': totalItems,
        'pendingOrders': pendingOrdersCount,
        'totalValue': totalValue,
        'activeRentals': activeRentals,
      };
    } catch (e) {
      debugPrint('Error fetching dashboard stats (returning defaults): $e');
      // Return empty stats on error (e.g. table missing)
      return {
        'shelves': 0,
        'items': 0,
        'pendingOrders': 0,
        'totalValue': 0.0,
        'activeRentals': [],
      };
    }
  }

  // --- Recent Activity (History) ---

  Future<List<DashboardActivity>> getRecentActivity({int limit = 5}) async {
    final sellerId = _supabase.auth.currentUser?.id;
    if (sellerId == null) {
       final allActivities = [..._localActivity];
       for (var inv in _localInvoices) {
        allActivities.add(DashboardActivity(
          id: inv.id,
          title: inv.paid ? 'Payment Success' : 'Invoice Generated',
          subtitle: '${inv.amount} AED • ${inv.paid ? 'PAID' : 'PENDING'}',
          date: inv.date,
          type: ActivityType.invoice,
        ));
       }
       allActivities.sort((a, b) => b.date.compareTo(a.date));
       return allActivities.take(limit).toList();
    }

    try {
      final List<DashboardActivity> activities = [];

      // 1. Inbound Requests
      final inboundData = await _supabase
          .from('sme_inbound_requests')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      for (var item in (inboundData as List)) {
        activities.add(DashboardActivity(
          id: item['id'],
          title: 'Inbound Shipment',
          subtitle: '${item['item_count']} items • ${(item['status'] as String).toUpperCase()}',
          date: DateTime.parse(item['created_at']),
          type: ActivityType.inbound,
        ));
      }

      // 2. Outbound Orders
      final ordersData = await _supabase
          .from('sme_orders')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (var item in (ordersData as List)) {
        activities.add(DashboardActivity(
          id: item['id'],
          title: 'Delivery Order',
          subtitle: 'To ${item['customer_name']} • ${(item['status'] as String).toUpperCase()}',
          date: DateTime.parse(item['created_at']),
          type: ActivityType.delivery,
        ));
      }

      // 3. New Subscriptions
      final subsData = await _supabase
          .from('sme_subscriptions')
          .select('*, warehouses(name)')
          .eq('seller_id', sellerId)
          .order('start_date', ascending: false)
          .limit(limit);

      for (var item in (subsData as List)) {
        activities.add(DashboardActivity(
          id: item['id'],
          title: 'Space Rented',
          subtitle: '${item['warehouses']['name'] ?? 'Warehouse'} • ${item['shelves_count']} Shelves',
          date: DateTime.parse(item['start_date']),
          type: ActivityType.rental,
        ));
      }

      // 4. Invoices (Payments)
      final invoiceData = await _supabase
          .from('sme_invoices')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(limit);

      for (var item in (invoiceData as List)) {
        final isPaid = item['paid'] as bool? ?? false;
        activities.add(DashboardActivity(
          id: item['id'],
          title: isPaid ? 'Payment Success' : 'Invoice Generated',
          subtitle: '${item['amount']} AED • ${isPaid ? 'PAID' : 'PENDING'}',
          date: DateTime.parse(item['created_at']),
          type: ActivityType.invoice,
        ));
      }

      // 4. Sort and Limit
      activities.sort((a, b) => b.date.compareTo(a.date));
      
      // Combine with local ACTIVITY
      activities.addAll(_localActivity);

      // Combine with local INVOICES (mapped)
      for (var inv in _localInvoices) {
        activities.add(DashboardActivity(
          id: inv.id,
          title: inv.paid ? 'Payment Success' : 'Invoice Generated',
          subtitle: '${inv.amount} AED • ${inv.paid ? 'PAID' : 'PENDING'}',
          date: inv.date,
          type: ActivityType.invoice,
        ));
      }

      activities.sort((a, b) => b.date.compareTo(a.date));

      if (activities.length > limit) {
        return activities.sublist(0, limit);
      }
      return activities;

    } catch (e) {
      debugPrint('Error fetching activity (fallback to local): $e');
      final allActivities = [..._localActivity];
      // Also include local invoices in fallback
      for (var inv in _localInvoices) {
        allActivities.add(DashboardActivity(
          id: inv.id,
          title: inv.paid ? 'Payment Success' : 'Invoice Generated',
          subtitle: '${inv.amount} AED • ${inv.paid ? 'PAID' : 'PENDING'}',
          date: inv.date,
          type: ActivityType.invoice,
        ));
      }
      allActivities.sort((a, b) => b.date.compareTo(a.date));
      return allActivities.take(limit).toList();
    }
  }

  // --- Products ---

  Future<List<SmeProduct>> getProducts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('sme_products')
        .select()
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);
    
    return (response as List).map((e) => SmeProduct.fromJson(e)).toList();
  }

  Future<String?> uploadImage(dynamic file) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final userId = user.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExt = 'jpg'; // simplifying for demo
      final fileName = '$userId/$timestamp.$fileExt';

      await _supabase.storage.from('product-images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _supabase.storage.from('product-images').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> addProduct(String name, String description, double price, String photoUrl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('sme_products').insert({
      'seller_id': user.id,
      'name': name,
      'description': description,
      'price': price,
      'photo_url': photoUrl,
    });
  }

  // --- Inventory ---

  Future<List<SmeInventory>> getInventory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Join with products to get names
      final response = await _supabase
          .from('sme_inventory')
          .select('*, sme_products(name)')
          .eq('seller_id', user.id);

      return (response as List).map((e) => SmeInventory.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching inventory (returning empty): $e');
      return [];
    }
  }

  // --- Drop-off Requests ---

  Future<void> createDropOffRequest(DateTime date, int count, String notes, {int laborCount = 0, bool inspection = false, String? warehouseId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('sme_inbound_requests').insert({
      'seller_id': user.id,
      'warehouse_id': warehouseId,
      'expected_date': date.toIso8601String(),
      'item_count': count,
      'labor_count': laborCount,
      'visual_inspection_requested': inspection,
      'notes': notes,
      'status': 'pending',
      'gate_pass_code': 'GP-${DateTime.now().millisecondsSinceEpoch}', // Mock Gate Pass
    });
  }

  // --- Outbound Orders (Delivery) ---



  // --- Subscriptions ---

  Future<void> createSubscription(String warehouseId, int shelvesCount, int durationMonths, double totalAmount) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
       // Guest Mode Activity
      _localActivity.add(DashboardActivity(
        id: 'L-SUB-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Space Rented',
        subtitle: 'Warehouse $warehouseId • $shelvesCount Shelves',
        date: DateTime.now(),
        type: ActivityType.rental,
      ));
      _saveLocal(); // Persist
      updateNotifier.value++; // Notify UI
      return;
    }

    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: durationMonths * 30));
    
    try {
      await _supabase.from('sme_subscriptions').insert({
        'seller_id': user.id,
        'warehouse_id': warehouseId,
        'shelves_count': shelvesCount,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': true,
      });
    } catch (e) {
      debugPrint('Error creating subscription (fallback): $e');
      // Fallback
       _localActivity.add(DashboardActivity(
        id: 'L-SUB-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Space Rented',
        subtitle: 'Warehouse $warehouseId • $shelvesCount Shelves',
        date: DateTime.now(),
        type: ActivityType.rental,
      ));
       _saveLocal(); // Persist
    }
    updateNotifier.value++; // Notify UI
  }

  // --- Invoices ---

  Future<void> createInvoice(Invoice invoice) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _localInvoices.add(invoice);
      _saveLocal(); // Persist
      updateNotifier.value++; // Notify UI
      return;
    }
    
    // Ensure we use the logged-in user's ID for security
    final data = invoice.toJson();
    data['seller_id'] = user.id;
    // Remove 'id' if you want Supabase to generate it, OR keep it if we generate UUIDs locally.
    // Since we generate UUIDs in the app:
    
    try {
      await _supabase.from('sme_invoices').insert(data);
    } catch (e) {
        debugPrint('Error saving invoice (fallback): $e');
        debugPrint('Error saving invoice (fallback): $e');
        _localInvoices.add(invoice);
        _saveLocal(); // Persist
    }
    updateNotifier.value++; // Notify UI
  }

  Future<List<Invoice>> getInvoices() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return List.from(_localInvoices);

    try {
      final response = await _supabase
          .from('sme_invoices')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      final remoteList = (response as List).map((e) => Invoice.fromJson(e)).toList();
      // Combine with local invoice if any (e.g. created during offline/fallback)
      final all = [..._localInvoices, ...remoteList];
       // dedupe based on ID
      final ids = <String>{};
      final deduped = <Invoice>[];
      for (var i in all) {
        if (ids.add(i.id)) deduped.add(i);
      }
      return deduped;

    } catch (e) {
      debugPrint('Error loading invoices (fallback): $e');
      return List.from(_localInvoices);
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, bool isPaid) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      final index = _localInvoices.indexWhere((i) => i.id == invoiceId);
      if (index != -1) {
        final old = _localInvoices[index];
        _localInvoices[index] = Invoice(
          id: old.id,
          number: old.number,
          warehouseName: old.warehouseName,
          date: old.date,
          amount: old.amount,
          vat: old.vat,
          paid: isPaid,
          type: old.type,
          metaData: old.metaData,
        );
      }
      _saveLocal(); // Persist
      updateNotifier.value++;
      return;
    }
    
    try {
      await _supabase
          .from('sme_invoices')
          .update({'paid': isPaid})
          .eq('id', invoiceId);
    } catch (e) {
      debugPrint('Error updating invoice status (fallback): $e');
      // Update local storage as fallback so UI remains correct
       final index = _localInvoices.indexWhere((i) => i.id == invoiceId);
       if (index != -1) {
        final old = _localInvoices[index];
        _localInvoices[index] = Invoice(
          id: old.id,
          number: old.number,
          warehouseName: old.warehouseName,
          date: old.date,
          amount: old.amount,
          vat: old.vat,
          paid: isPaid,
          type: old.type,
          metaData: old.metaData,
        );
        _saveLocal(); // Persist
      }
    }
    updateNotifier.value++;
  }

  // --- Admin Logic (For Logic Blueprint) ---

  /// Fetches pending tasks for the Admin Dashboard.
  /// Ideally, this would filter by the Admin's specific warehouse assignment.
  Future<List<Map<String, dynamic>>> getAdminTasks() async {
    // In a real app, we check if the user is an admin.
    // For this prototype, we just return all pending inbound requests.
    
    try {
      final response = await _supabase
          .from('sme_inbound_requests')
          .select('*, sme_subscriptions(sme_inventory(*))') // Join for context if needed
          .eq('status', 'pending')
          .order('expected_date', ascending: true);

      final List<Map<String, dynamic>> tasks = [];

      for (var item in (response as List)) {
        final date = DateTime.parse(item['expected_date']);
        final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
        
        // Determine Badge
        String badge = 'Standard';
        Color color = const Color(0xFF9E9E9E); // Grey
        
        if (item['labor_count'] > 0) {
          badge = 'Workers Needed';
          color = const Color(0xFF2196F3); // Blue
        } else if (item['visual_inspection_requested'] == true) {
          badge = 'Inspection';
          color = const Color(0xFFFF9800); // Orange
        }

        tasks.add({
          'id': item['id'], // Real DB ID
          'time': timeStr,
          'title':  'Gate Pass ${item['gate_pass_code'] ?? 'N/A'}',
          'subtitle': '${item['item_count']} Boxes • ${item['notes'] ?? 'No notes'}',
          'badge': badge,
          'color': color,
          'type': 'receive', // For now only handling receiving
          'raw': item, // Keep raw data for detail screen
        });
      }
      return tasks;
    } catch (e) {
      debugPrint('Error fetching admin tasks: $e');
      return [];
    }
  }


  /// Completes a receiving task (moves to 'received' or 'completed')
  Future<void> completeInboundRequest(String id, bool hasDamage, String? damagePhotoUrl) async {
    try {
      await _supabase.from('sme_inbound_requests').update({
        'status': 'received',
        // In a real schema, we'd log the 'received_at' and 'damage_notes' here too
      }).eq('id', id);

      // Trigger stock update logic (In a real backend, this is a trigger/edge function).
      // Here we simulate it by finding the user's inventory and incrementing it.
      // But for this "Fix & Finish", updating the status is the key "Task Completion".
      
      updateNotifier.value++;
    } catch (e) {
      debugPrint('Error completing inbound request: $e');
    }
  }

  // --- Domain B: Pricing Engine ---
  
  /// Centralized Pricing Logic.
  /// Formula: (Shelves * 100 * Months) + (Workers * 50)
  double calculateRentalPrice(int shelves, int months, bool addWorkers, int workerCount) {
    const double pricePerShelf = 100.0;
    const double workerFee = 50.0;
    
    double base = (shelves * pricePerShelf * months);
    double labor = addWorkers ? (workerCount * workerFee) : 0.0;
    
    return base + labor;
  }

  // --- Domain D & E: Outbound Logistics (Atomic Check) ---

  Future<bool> createDeliveryRequest(String name, String address, String method) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Guest logic preserved from earlier
       _localActivity.add(DashboardActivity(
        id: 'L-DEL-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Delivery Requested',
        subtitle: 'To $name • ${method.toUpperCase()}',
        date: DateTime.now(),
        type: ActivityType.delivery,
      ));
      _saveLocal();
      updateNotifier.value++;
      return true;
    }

    try {
      // 1. Transactional Integrity Check (Simulated in Service Layer)
      // We assume the user is shipping *one* item for this simplified flow, 
      // or we just check if they have active subscription space (dummy check for stock).
      // A Real implementation would take List<Items> and decrement specific SKU quantities.
      
      // For this demo: We create the order.
      await _supabase.from('sme_orders').insert({
        'seller_id': user.id,
        'customer_name': name,
        'customer_address': address,
        'delivery_method': method,
        'status': 'pending',
        'total_amount': 0.0, // Placeholder
      });
      
      // 2. Atomic Decrement (Simulated)
      // await _supabase.rpc('decrement_stock', params: {'item_id': ..., 'qty': ...});
      
      updateNotifier.value++;
      return true;
    } catch (e) {
      debugPrint('Error creating delivery: $e');
      return false;
    }
  }

  // --- Marketplace Shops ---
  
  static MarketplaceShop? _localShop;

  Future<MarketplaceShop?> getMyShop() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return _localShop;

    try {
      final response = await _supabase
          .from('marketplace_shops')
          .select()
          .eq('seller_id', user.id)
          .maybeSingle();
      
      if (response != null) {
        return MarketplaceShop.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting shop (DB table might not exist): $e');
      return _localShop; // Fallback for demo
    }
  }

  Future<bool> createShop(String shopName, String licenseName) async {
    final user = _supabase.auth.currentUser;
    final newShop = MarketplaceShop(
        id: 'SHOP-${DateTime.now().millisecondsSinceEpoch}',
        sellerId: user?.id ?? 'GUEST',
        shopName: shopName,
        licenseName: licenseName,
        isVerified: false, // Default false until admin approves
        createdAt: DateTime.now(),
    );

    if (user == null) {
      if (_localShop != null) return false; // Prevent duplicate
      _localShop = newShop;
      updateNotifier.value++;
      return true;
    }

    try {
      // First check if one already exists
      final existing = await _supabase.from('marketplace_shops').select().eq('seller_id', user.id).maybeSingle();
      if (existing != null) return false;

      await _supabase.from('marketplace_shops').insert(newShop.toJson());
      updateNotifier.value++;
      return true;
    } catch (e) {
      debugPrint('Error creating shop (fallback to local): $e');
      if (_localShop != null) return false; // Prevent duplicate fallback
      _localShop = newShop;
      updateNotifier.value++;
      return true; // Still return true for demo UX
    }
  }

  Future<void> forceVerifyShop() async {
    final user = _supabase.auth.currentUser;
    
    // Update local mock
    if (_localShop != null) {
      _localShop = MarketplaceShop(
        id: _localShop!.id,
        sellerId: _localShop!.sellerId,
        shopName: _localShop!.shopName,
        licenseName: _localShop!.licenseName,
        isVerified: true,
        createdAt: _localShop!.createdAt,
      );
    }
    
    if (user != null) {
      try {
        await _supabase
            .from('marketplace_shops')
            .update({'is_verified': true})
            .eq('seller_id', user.id);
      } catch (e) {
        debugPrint('Error force verifying shop in DB: $e');
      }
    }
    
    updateNotifier.value++;
  }

  Future<List<SmeProduct>> getPublicMarketplaceProducts() async {
    try {
      // In a real database, this is an inner join:
      // select products.*, shops.shop_name from sme_products products
      // join marketplace_shops shops on products.seller_id = shops.seller_id
      // where shops.is_verified = true
      
      final response = await _supabase
          .from('sme_products')
          .select('*, marketplace_shops!inner(shop_name, is_verified)')
          .eq('marketplace_shops.is_verified', true)
          .order('created_at', ascending: false);
          
      return (response as List).map((e) {
        // Flatten the joined data
        e['shop_name'] = e['marketplace_shops']['shop_name'];
        e['is_shop_verified'] = e['marketplace_shops']['is_verified'];
        return SmeProduct.fromJson(e);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching public marketplace products: $e');
      // Mock data for demo
      return [
        SmeProduct(
            id: 'mock1',
            sellerId: 's1',
            name: 'Premium Espresso Beans',
            description: 'Locally roasted in UAE',
            price: 45.0,
            shopName: 'Arabica Coffee Roasters',
            isShopVerified: true,
            createdAt: DateTime.now(),
        ),
        SmeProduct(
            id: 'mock2',
            sellerId: 's2',
            name: 'Wireless Earbuds',
            description: 'Noise cancelling, 20h battery',
            price: 120.0,
            shopName: 'Tech Haven LLC',
            isShopVerified: true,
            createdAt: DateTime.now(),
        ),
        SmeProduct(
            id: 'mock3',
            sellerId: 's3',
            name: 'Handcrafted Vase',
            description: 'Ceramic decor',
            price: 85.0,
            shopName: 'Dubai Arts',
            isShopVerified: true,
            createdAt: DateTime.now(),
        ),
      ];
    }
  }

  // --- Admin/Operations APIs ---

  Future<List<Invoice>> getAdminInvoices(InvoiceType type) async {
    final user = _supabase.auth.currentUser;
    
    // Global query for admin panel (no seller_id filter)
    if (user != null) {
      try {
        final response = await _supabase
            .from('sme_invoices')
            .select()
            .eq('type', type.name)
            .order('created_at', ascending: false);
            
        return (response as List).map((e) => Invoice.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error fetching admin invoices: $e');
      }
    }
    
    // Local / Offline fallback
    return _localInvoices.where((e) => e.type == type).toList();
  }

  Future<void> dispatchDeliveryOrder(String invoiceId) async {
    final user = _supabase.auth.currentUser;
    
    // Remove locally
    _localInvoices.removeWhere((e) => e.id == invoiceId);
    _saveLocal();
    
    if (user != null) {
      try {
        // Mark as paid or complete (we delete in this prototype to clear queue)
        await _supabase.from('sme_invoices').delete().eq('id', invoiceId);
      } catch (e) {
        debugPrint('Error deleting dispatch order: $e');
      }
    }
    
    updateNotifier.value++;
  }
}
