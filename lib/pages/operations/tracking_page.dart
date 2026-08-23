import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

class TrackingPage extends StatelessWidget {
  final String? trackingId;

  const TrackingPage({super.key, this.trackingId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final tId = trackingId ?? 'TRK-99281102';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.trackingTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Map Placeholder
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFE5E7EB), // Grey Map BG
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          isAr ? 'جاري تحميل الخريطة المباشرة...' : 'Map View Loading...',
                          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Simulated Route Line
                  Positioned(
                    bottom: 40,
                    left: 40,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping, color: AppColors.bluePrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.estimatedDelivery, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(isAr ? 'اليوم، 4:30 مساءً' : 'Today, 4:30 PM', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(l10n.statusInTransit, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Timeline
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.trackingNumber}: $tId',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        _TimelineItem(
                          title: isAr ? 'جاري التوصيل حالياً' : 'Out for Delivery',
                          time: isAr ? '10:30 صباحاً' : '10:30 AM',
                          location: isAr ? 'دبي، الإمارات' : 'Dubai, UAE',
                          isCompleted: true,
                          isCurrent: true,
                        ),
                        _TimelineItem(
                          title: isAr ? 'وصل إلى مركز الفرز والتوزيع' : 'Arrived at Sort Facility',
                          time: isAr ? '06:15 صباحاً' : '06:15 AM',
                          location: isAr ? 'مركز دبي (القوز)' : 'Al Quoz Hub',
                          isCompleted: true,
                        ),
                        _TimelineItem(
                          title: isAr ? 'تم استلام الشحنة من التاجر' : 'Picked Up',
                          time: isAr ? 'أمس، 4:00 مساءً' : 'Yesterday, 4:00 PM',
                          location: isAr ? 'مستودع التاجر' : 'Merchant Warehouse',
                          isCompleted: true,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.time,
    required this.location,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, // Larger Dot
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? AppColors.bluePrimary : (isCompleted ? Colors.blue[100] : Colors.grey[300]),
                border: isCurrent ? Border.all(color: Colors.blue[100]!, width: 6) : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 4, // Thicker Line
                height: 60, // Longer Line
                color: Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCompleted ? Colors.black : Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(time, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(width: 8),
                  const Icon(Icons.circle, size: 4, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(location, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
