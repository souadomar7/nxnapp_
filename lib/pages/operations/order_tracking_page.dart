import 'package:flutter/material.dart';
import '../../theme.dart';

class OrderTrackingPage extends StatelessWidget {
  final String? orderId;
  final String? productName;
  final String? currentStatus; // pending, confirmed, preparing, ready_for_shipment, shipped, delivered

  const OrderTrackingPage({super.key, this.orderId, this.productName, this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final steps = [
      _OrderStep(
        icon: Icons.shopping_bag_rounded,
        titleEn: 'Order Placed',
        titleAr: 'تم استلام الطلب',
        descEn: 'Your order has been received and the merchant has been notified.',
        descAr: 'تم استلام طلبك وإخطار التاجر.',
        status: 'pending',
      ),
      _OrderStep(
        icon: Icons.inventory_2_rounded,
        titleEn: 'Merchant Preparing',
        titleAr: 'التاجر يجهّز الطلب',
        descEn: 'The merchant is preparing your items for shipment.',
        descAr: 'يقوم التاجر بتجهيز منتجاتك للشحن.',
        status: 'preparing',
      ),
      _OrderStep(
        icon: Icons.warehouse_rounded,
        titleEn: 'Ready for Shipment',
        titleAr: 'جاهز للشحن',
        descEn: 'Your order is ready and awaiting courier pickup.',
        descAr: 'طلبك جاهز وينتظر استلام شركة الشحن.',
        status: 'ready_for_shipment',
      ),
      _OrderStep(
        icon: Icons.local_shipping_rounded,
        titleEn: 'Shipped',
        titleAr: 'في الطريق',
        descEn: 'Your order is on its way to you.',
        descAr: 'طلبك في طريقه إليك.',
        status: 'shipped',
      ),
      _OrderStep(
        icon: Icons.done_all_rounded,
        titleEn: 'Delivered',
        titleAr: 'تم التسليم',
        descEn: 'Your order has been delivered successfully.',
        descAr: 'تم تسليم طلبك بنجاح!',
        status: 'delivered',
      ),
    ];

    final statusOrder = ['pending', 'preparing', 'ready_for_shipment', 'shipped', 'delivered'];
    final currentIdx = statusOrder.indexOf(currentStatus ?? 'pending');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? 'تتبع الطلب' : 'Track Order',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (orderId != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppColors.bluePrimary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isAr ? 'رقم الطلب' : 'Order Reference',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        Text('#$orderId',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.bluePrimary)),
                      ],
                    ),
                    if (productName != null) ...[
                      const Spacer(),
                      Expanded(
                        child: Text(productName!,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'حالة الطلب' : 'Order Status',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final isDone = idx <= currentIdx;
              final isActive = idx == currentIdx;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.bluePrimary : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          boxShadow: isActive ? [
                            BoxShadow(color: AppColors.bluePrimary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)
                          ] : [],
                        ),
                        child: Icon(step.icon, color: isDone ? Colors.white : Colors.grey.shade400, size: 22),
                      ),
                      if (idx < steps.length - 1)
                        Container(
                          width: 2,
                          height: 48,
                          color: isDone && idx < currentIdx ? AppColors.bluePrimary : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? step.titleAr : step.titleEn,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDone ? AppColors.textPrimary : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? step.descAr : step.descEn,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDone ? Colors.grey.shade600 : Colors.grey.shade400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.support_agent_outlined),
              label: Text(isAr ? 'تواصل مع الدعم' : 'Contact Support'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStep {
  final IconData icon;
  final String titleEn, titleAr, descEn, descAr, status;
  const _OrderStep({required this.icon, required this.titleEn, required this.titleAr,
    required this.descEn, required this.descAr, required this.status});
}
