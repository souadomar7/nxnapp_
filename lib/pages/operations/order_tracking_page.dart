import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';

class OrderTrackingPage extends StatefulWidget {
  final String? orderId;
  final String? trackingId;
  final String? productName;
  final String? currentStatus; // pending, confirmed, preparing, ready_for_shipment, shipped, delivered

  const OrderTrackingPage({
    super.key,
    this.orderId,
    this.trackingId,
    this.productName,
    this.currentStatus,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late String _status;
  String? _resolvedOrderId;
  String? _resolvedProductName;
  bool _isLoading = false;

  String? get targetOrderId => widget.orderId ?? widget.trackingId ?? _resolvedOrderId;
  String? get targetProductName => widget.productName ?? _resolvedProductName;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus ?? 'pending';
    _resolvedOrderId = widget.orderId ?? widget.trackingId;
    _resolvedProductName = widget.productName;
    MarketplaceService.updateNotifier.addListener(_onMarketplaceUpdate);
    _refreshStatus();
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_onMarketplaceUpdate);
    super.dispose();
  }

  void _onMarketplaceUpdate() {
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final tId = targetOrderId;
    try {
      if (tId != null) {
        final sellerOrders = await MarketplaceService().getOrdersForSeller();
        final matchSeller = sellerOrders.firstWhere(
          (o) => o['id'] == tId,
          orElse: () => {},
        );
        if (matchSeller.isNotEmpty && matchSeller['status'] != null) {
          if (mounted) {
            setState(() {
              _status = matchSeller['status'] as String;
              if (matchSeller['product_name'] != null) {
                _resolvedProductName = matchSeller['product_name'].toString();
              }
            });
          }
          return;
        }

        final buyerOrders = await MarketplaceService().getOrdersForBuyer();
        final matchBuyer = buyerOrders.firstWhere(
          (o) => o['id'] == tId,
          orElse: () => {},
        );
        if (matchBuyer.isNotEmpty && matchBuyer['status'] != null) {
          if (mounted) {
            setState(() {
              _status = matchBuyer['status'] as String;
              if (matchBuyer['product_name'] != null) {
                _resolvedProductName = matchBuyer['product_name'].toString();
              }
            });
          }
          return;
        }
      } else {
        // No specific ID passed: look up the user's latest active order
        final buyerOrders = await MarketplaceService().getOrdersForBuyer();
        if (buyerOrders.isNotEmpty) {
          final latest = buyerOrders.first;
          if (mounted) {
            setState(() {
              _resolvedOrderId = latest['id']?.toString();
              _resolvedProductName = latest['product_name']?.toString() ?? latest['products']?['name']?.toString();
              _status = latest['status']?.toString() ?? 'pending';
            });
          }
          return;
        }

        final sellerOrders = await MarketplaceService().getOrdersForSeller();
        if (sellerOrders.isNotEmpty) {
          final latest = sellerOrders.first;
          if (mounted) {
            setState(() {
              _resolvedOrderId = latest['id']?.toString();
              _resolvedProductName = latest['product_name']?.toString() ?? latest['products']?['name']?.toString();
              _status = latest['status']?.toString() ?? 'pending';
            });
          }
          return;
        }
      }
    } catch (_) {}
  }

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
    var currentIdx = statusOrder.indexOf(_status);
    if (currentIdx == -1) {
      currentIdx = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? 'تتبع الطلب' : 'Track Order',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () async {
              setState(() => _isLoading = true);
              await _refreshStatus();
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live GPS Route Card
                  Container(
                    height: 165,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.12,
                            child: CustomPaint(
                              painter: _RouteGridPainter(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10AC84).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.navigation_rounded, color: Color(0xFF10AC84), size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? 'تتبع الشحنة المباشر عبر GPS' : 'Live GPS Delivery Tracking',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            isAr ? 'أسطول NXN اللوجستي المعتمد' : 'NXN Certified Dispatch Fleet',
                                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _status == 'delivered'
                                          ? const Color(0xFF10AC84)
                                          : _status == 'shipped'
                                              ? Colors.blueAccent
                                              : const Color(0xFFFF9F43),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _status == 'delivered'
                                          ? (isAr ? 'تم التسليم' : 'Delivered')
                                          : _status == 'shipped'
                                              ? (isAr ? 'في الطريق 🚚' : 'In Transit 🚚')
                                              : (isAr ? 'قيد التجهيز 📦' : 'Preparing 📦'),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? 'الموعد المتوقع لوصول الشحنة' : 'Estimated Delivery Window',
                                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                                          ),
                                          Text(
                                            _status == 'delivered'
                                                ? (isAr ? 'تم التسليم بنجاح إلى العميل' : 'Delivered Successfully')
                                                : (isAr ? 'اليوم، خلال 2-4 ساعات ⚡' : 'Today, within 2-4 hours ⚡'),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Order Reference Info
                  if (targetOrderId != null)
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
                              Text('#$targetOrderId',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.bluePrimary)),
                            ],
                          ),
                          if (targetProductName != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                targetProductName!,
                                textAlign: isAr ? TextAlign.left : TextAlign.end,
                                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    isAr ? 'حالة الشحنة والمسار' : 'Shipment Journey',
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
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.bluePrimary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
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
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 20),
                              Text(isAr ? 'مركز مساعدة التوصيل' : 'Delivery Support Center', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(isAr ? 'فريق الدعم اللوجستي متاح 24/7 لخدمتكم' : 'Our logistics dispatch team is available 24/7 to assist you.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFF10AC84), child: Icon(Icons.support_agent, color: Colors.white)),
                                title: Text(isAr ? 'المحادثة الفورية' : 'Live Chat with Dispatch'),
                                subtitle: Text(isAr ? 'متوسط الرد: أقل من دقيقة' : 'Avg response: < 1 min'),
                                onTap: () => Navigator.pop(context),
                              ),
                              ListTile(
                                leading: const CircleAvatar(backgroundColor: AppColors.bluePrimary, child: Icon(Icons.call, color: Colors.white)),
                                title: Text(isAr ? 'اتصال مباشر بالسائق / المشرف' : 'Call Logistics Hotline'),
                                subtitle: const Text('800-NXN-DELIVERY'),
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.support_agent_outlined),
                    label: Text(isAr ? 'تواصل مع الدعم اللوجستي' : 'Contact Delivery Support'),
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

class _RouteGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF10AC84)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(20, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.2, size.width * 0.8, size.height * 0.5);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderStep {
  final IconData icon;
  final String titleEn, titleAr, descEn, descAr, status;
  const _OrderStep({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.descEn,
    required this.descAr,
    required this.status,
  });
}
