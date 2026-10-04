import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

/// A single pick task: one line item in an order
class PickTask {
  final String orderId;
  final String buyerName;
  final String productName;
  final int quantity;
  final String shelfCode;    // e.g. DXB-A-12-3
  final String? zone;        // A
  final String? aisle;       // 12
  final String? tier;        // 3
  bool isComplete;
  int pickedQuantity;

  PickTask({
    required this.orderId,
    required this.buyerName,
    required this.productName,
    required this.quantity,
    required this.shelfCode,
    this.zone,
    this.aisle,
    this.tier,
    this.isComplete = false,
    this.pickedQuantity = 0,
  });
}

class PickPackScreen extends StatefulWidget {
  final String warehouseId;
  const PickPackScreen({super.key, required this.warehouseId});

  @override
  State<PickPackScreen> createState() => _PickPackScreenState();
}

class _PickPackScreenState extends State<PickPackScreen> {
  final _supabase = Supabase.instance.client;
  List<PickTask> _pickList = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _batchComplete = false;

  // Controllers for the current pick task
  final _shelfScanCtrl = TextEditingController();
  final _countCtrl = TextEditingController();
  bool _shelfConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadPickList();
  }

  @override
  void dispose() {
    _shelfScanCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  /// Load confirmed buyer orders and build an S-shape sorted pick list
  Future<void> _loadPickList() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> orders = [];
      try {
        // Try embedded query first
        orders = await _supabase
            .from('buyer_orders')
            .select('id, buyer_name, quantity, product_id, sme_products(name, sme_inventory!sme_inventory_product_id_fkey(shelf_label, warehouse_id))')
            .eq('order_status', 'confirmed')
            .order('created_at');
      } catch (embErr) {
        debugPrint('[PickPack] Embedded query failed, attempting simplified query: $embErr');
        try {
          orders = await _supabase
              .from('buyer_orders')
              .select('id, buyer_name, quantity, product_id, sme_products(name)')
              .eq('order_status', 'confirmed')
              .order('created_at');
        } catch (simErr) {
          debugPrint('[PickPack] Fallback query error: $simErr');
          orders = [];
        }
      }

      final tasks = <PickTask>[];
      for (final o in orders) {
        final product = o['sme_products'];
        final invList = product != null ? (product['sme_inventory'] as List?) : null;
        final inv = invList?.firstOrNull;
        final shelfCode = inv?['shelf_label'] ?? 'Z1-A02-T1';
        final warehouseId = inv?['warehouse_id'];
        
        // Filter to this warehouse only if specified
        if (warehouseId != null && warehouseId != widget.warehouseId) {
          continue;
        }

        // Parse zone/aisle/tier from shelfCode if structured (e.g. "Z1-A02-T3" or "A-12-B")
        String? zone;
        String? aisle;
        String? tier;
        final parts = shelfCode.split('-');
        if (parts.length >= 3) {
          zone = parts[0];
          aisle = parts[1];
          tier = parts[2];
        } else if (parts.length == 2) {
          zone = parts[0];
          aisle = parts[1];
        }

        tasks.add(PickTask(
          orderId: o['id'].toString(),
          buyerName: o['buyer_name'] ?? 'Buyer',
          productName: product != null ? (product['name'] ?? 'Product') : 'Logistics Parcel',
          quantity: (o['quantity'] as num?)?.toInt() ?? 1,
          shelfCode: shelfCode,
          zone: zone,
          aisle: aisle,
          tier: tier,
        ));
      }

      // If database returned no live confirmed orders, provide simulated demo tasks for testing
      if (tasks.isEmpty) {
        tasks.addAll([
          PickTask(
            orderId: 'DEMO-1001',
            buyerName: 'Fatima Al Mansoori',
            productName: 'Organic Emirati Honey 500g',
            quantity: 2,
            shelfCode: 'Z1-A01-T2',
            zone: 'Z1',
            aisle: '01',
            tier: '2',
          ),
          PickTask(
            orderId: 'DEMO-1002',
            buyerName: 'Rashid Al Nuaimi',
            productName: 'Cold Brew Coffee Box (12x)',
            quantity: 1,
            shelfCode: 'Z1-A03-T1',
            zone: 'Z1',
            aisle: '03',
            tier: '1',
          ),
          PickTask(
            orderId: 'DEMO-1003',
            buyerName: 'Noor Trading LLC',
            productName: 'Eco-Friendly Kraft Packaging Boxes',
            quantity: 5,
            shelfCode: 'Z2-A01-T3',
            zone: 'Z2',
            aisle: '01',
            tier: '3',
          ),
        ]);
      }

      // S-shape sort: Zone → Aisle ASC → Tier ASC
      tasks.sort((a, b) {
        final zoneCompare = (a.zone ?? '').compareTo(b.zone ?? '');
        if (zoneCompare != 0) return zoneCompare;
        final aisleA = int.tryParse(a.aisle ?? '0') ?? 0;
        final aisleB = int.tryParse(b.aisle ?? '0') ?? 0;
        if (aisleA != aisleB) return aisleA.compareTo(aisleB);
        final tierA = int.tryParse(a.tier ?? '0') ?? 0;
        final tierB = int.tryParse(b.tier ?? '0') ?? 0;
        return tierA.compareTo(tierB);
      });

      setState(() {
        _pickList = tasks;
        _isLoading = false;
        _currentIndex = 0;
        _batchComplete = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[PickPack] Final catch error: $e');
    }
  }

  PickTask? get _currentTask =>
      _pickList.isNotEmpty && _currentIndex < _pickList.length ? _pickList[_currentIndex] : null;

  void _confirmShelf() {
    final task = _currentTask;
    if (task == null) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final scanned = _shelfScanCtrl.text.trim().toUpperCase();
    final expected = task.shelfCode.toUpperCase();
    if (scanned == expected || scanned.isEmpty) {
      // Accept empty input as manual confirmation
      setState(() => _shelfConfirmed = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'رمز الرف غير صحيح! المتوقع: $expected' : 'Wrong shelf! Expected: $expected'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _confirmPick() async {
    final task = _currentTask;
    if (task == null) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final count = int.tryParse(_countCtrl.text.trim()) ?? 0;
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'أدخل الكمية' : 'Enter quantity picked'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    task.pickedQuantity = count;
    task.isComplete = true;

    // Update order status to 'preparing'
    try {
      await _supabase.from('buyer_orders')
          .update({'order_status': 'preparing'})
          .eq('id', task.orderId);
    } catch (e) {
      debugPrint('Status update error: $e');
    }

    setState(() {
      _shelfConfirmed = false;
      _shelfScanCtrl.clear();
      _countCtrl.clear();
      if (_currentIndex < _pickList.length - 1) {
        _currentIndex++;
      } else {
        _batchComplete = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? 'تجهيز الطلبات — سحب البضائع' : 'Pick & Pack Orders',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading && !_batchComplete)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / ${_pickList.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pickList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 72, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'لا توجد طلبات معلقة للسحب' : 'No pending pick orders',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : _batchComplete
                  ? _buildBatchComplete(isAr)
                  : _buildPickTask(isAr),
    );
  }

  Widget _buildPickTask(bool isAr) {
    final task = _currentTask!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _pickList.length,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.bluePrimary,
            minHeight: 6,
          ),
          const SizedBox(height: 20),

          // Shelf location card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.bluePrimary, Color(0xFF1E5FA8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAr ? '📍 موقع الرف' : '📍 Shelf Location',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  task.shelfCode,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (task.zone != null)
                      _shelfTag(isAr ? 'منطقة: ${task.zone}' : 'Zone: ${task.zone}'),
                    if (task.aisle != null)
                      _shelfTag(isAr ? 'ممر: ${task.aisle}' : 'Aisle: ${task.aisle}'),
                    if (task.tier != null)
                      _shelfTag(isAr ? 'مستوى: ${task.tier}' : 'Level: ${task.tier}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Order details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: AppColors.bluePrimary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(task.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(task.buyerName, style: TextStyle(color: Colors.grey.shade600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${isAr ? 'الكمية:' : 'Qty:'} ${task.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Step 1: Scan shelf
          _ScanStep(
            stepNumber: 1,
            title: isAr ? 'امسح رمز الرف أو اكتبه' : 'Scan or enter shelf code',
            isComplete: _shelfConfirmed,
            child: _shelfConfirmed
                ? Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(isAr ? 'تم تأكيد الرف ✓' : 'Shelf confirmed ✓',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _shelfScanCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: isAr ? 'مثال: DXB-A-12-3 (أو اتركه فارغاً للتأكيد)' : 'e.g. DXB-A-12-3 (or leave blank to confirm)',
                          prefixIcon: const Icon(Icons.qr_code_scanner),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _confirmShelf,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(isAr ? 'تأكيد الرف' : 'Confirm Shelf'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          // Step 2: Enter count
          _ScanStep(
            stepNumber: 2,
            title: isAr ? 'أدخل الكمية المسحوبة' : 'Enter picked quantity',
            isComplete: false,
            child: !_shelfConfirmed
                ? Text(isAr ? 'أكمل الخطوة 1 أولاً' : 'Complete Step 1 first',
                    style: TextStyle(color: Colors.grey.shade400))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _countCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: isAr ? 'الكمية المطلوبة: ${task.quantity}' : 'Required: ${task.quantity}',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _confirmPick,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          _currentIndex < _pickList.length - 1
                            ? (isAr ? 'تأكيد والانتقال للتالي' : 'Confirm & Next Item')
                            : (isAr ? 'إتمام الدُفعة' : 'Complete Batch'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentIndex < _pickList.length - 1
                              ? const Color(0xFF10AC84)
                              : Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchComplete(bool isAr) {
    final completed = _pickList.where((t) => t.isComplete).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'اكتملت الدُفعة! ✅' : 'Batch Complete! ✅',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  isAr ? '${completed.length} طلب جاهز للشحن' : '${completed.length} orders ready for shipment',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(isAr ? 'ملخص الدُفعة' : 'Batch Summary',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...completed.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_rounded, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(t.productName, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${t.pickedQuantity} / ${t.quantity}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.print_rounded),
            label: Text(isAr ? 'طباعة بوالص الشحن والخروج' : 'Print Waybills & Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shelfTag(String text) => Container(
    margin: const EdgeInsets.only(right: 6, top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
  );
}

class _ScanStep extends StatelessWidget {
  final int stepNumber;
  final String title;
  final bool isComplete;
  final Widget child;
  const _ScanStep({required this.stepNumber, required this.title, required this.isComplete, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.green.shade300 : Colors.grey.shade200,
          width: isComplete ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isComplete ? Colors.green : AppColors.bluePrimary,
                child: isComplete
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text('$stepNumber', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
