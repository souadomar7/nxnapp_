import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../operations/order_tracking_page.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  final MarketplaceService _service = MarketplaceService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _service.getOrdersForSeller();
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return AppColors.bluePrimary;
      case 'preparing': return Colors.purple;
      case 'ready_for_shipment': return Colors.indigo;
      case 'shipped': return Colors.green;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String? status, bool isAr) {
    switch (status) {
      case 'pending': return isAr ? 'جديد' : 'New';
      case 'confirmed': return isAr ? 'مؤكد' : 'Confirmed';
      case 'preparing': return isAr ? 'قيد التجهيز' : 'Preparing';
      case 'ready_for_shipment': return isAr ? 'جاهز للشحن' : 'Ready to Ship';
      case 'shipped': return isAr ? 'تم الشحن' : 'Shipped';
      case 'delivered': return isAr ? 'تم التسليم' : 'Delivered';
      case 'cancelled': return isAr ? 'ملغي' : 'Cancelled';
      default: return status ?? 'Unknown';
    }
  }

  Future<void> _changeStatus(String orderId, String currentStatus) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final nextStatuses = <String>['confirmed', 'preparing', 'ready_for_shipment', 'shipped', 'delivered'];
    final available = nextStatuses.where((s) => s != currentStatus).toList();
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isAr ? 'تحديث حالة الطلب' : 'Update Order Status',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...available.map((s) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(s).withValues(alpha: 0.15),
                child: Icon(Icons.circle, color: _statusColor(s), size: 12),
              ),
              title: Text(_statusLabel(s, isAr)),
              onTap: () => Navigator.pop(ctx, s),
            )),
          ],
        ),
      ),
    );
    if (selected != null) {
      await _service.updateOrderStatus(orderId, selected);
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(isAr ? 'الطلبات الواردة' : 'Incoming Orders',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(isAr ? 'لا توجد طلبات بعد' : 'No orders yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      final status = o['status'] as String?;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      o['customer_name'] ?? (isAr ? 'مشتري' : 'Buyer'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusLabel(status, isAr),
                                      style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'AED ${(o['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.bluePrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o['customer_address'] ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => OrderTrackingPage(orderId: o['id'], currentStatus: status),
                                      )),
                                      icon: const Icon(Icons.track_changes, size: 16),
                                      label: Text(isAr ? 'تتبع' : 'Track'),
                                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: status != 'delivered' && status != 'cancelled'
                                          ? () => _changeStatus(o['id'], status ?? 'pending')
                                          : null,
                                      icon: const Icon(Icons.update, size: 16),
                                      label: Text(isAr ? 'تحديث' : 'Update'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.bluePrimary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
