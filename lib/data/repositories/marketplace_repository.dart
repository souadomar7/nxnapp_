import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/app_exception.dart';
import '../../models/marketplace_models.dart';

class MarketplaceRepository {
  final SupabaseClient _supabase;

  MarketplaceRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch approved products for the public marketplace
  Future<List<SmeProduct>> getPublicProducts() async {
    try {
      final res = await _supabase
          .from('sme_products')
          .select('*, marketplace_shops(shop_name, is_approved)')
          .eq('is_hidden', false)
          .order('created_at', ascending: false);

      return (res as List).map((map) {
        final shop = map['marketplace_shops'] as Map<String, dynamic>?;
        return SmeProduct(
          id: map['id'],
          sellerId: map['seller_id'],
          name: map['name'] ?? '',
          nameAr: map['name_ar'],
          description: map['description'] ?? '',
          price: (map['price'] as num?)?.toDouble() ?? 0.0,
          quantity: (map['quantity'] as num?)?.toInt() ?? 0,
          photoUrl: map['photo_url'] ?? '',
          category: map['category'],
          shopName: shop?['shop_name'] ?? 'Verified Merchant',
          isShopApproved: shop?['is_approved'] ?? true,
          isHidden: map['is_hidden'] ?? false,
          createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching public products: $e');
      return [];
    }
  }

  /// Fetch merchant's own products
  Future<List<SmeProduct>> getMyProducts() async {
    final uid = _currentUserId;
    if (uid == null) return [];

    try {
      final res = await _supabase
          .from('sme_products')
          .select('*')
          .eq('seller_id', uid)
          .order('created_at', ascending: false);

      return (res as List).map((map) {
        return SmeProduct(
          id: map['id'],
          sellerId: map['seller_id'],
          name: map['name'] ?? '',
          nameAr: map['name_ar'],
          description: map['description'] ?? '',
          price: (map['price'] as num?)?.toDouble() ?? 0.0,
          photoUrl: map['photo_url'] ?? '',
          shopName: 'My Shop',
          isShopApproved: true,
          isHidden: map['is_hidden'] ?? false,
          createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching my products: $e');
      throw ServerException(message: 'Failed to fetch merchant products: $e', statusCode: 500);
    }
  }

  /// Fetch incoming orders for merchant
  Future<List<Map<String, dynamic>>> getSellerOrders() async {
    final uid = _currentUserId;
    if (uid == null) return [];

    try {
      final res = await _supabase
          .from('buyer_orders')
          .select('*, sme_products(name, photo_url)')
          .eq('seller_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching seller orders: $e');
      return [];
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('buyer_orders')
          .update({'order_status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      debugPrint('Error updating order status: $e');
      throw ServerException(message: 'Failed to update order: $e', statusCode: 500);
    }
  }
}
