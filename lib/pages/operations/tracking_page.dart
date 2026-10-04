import 'package:flutter/material.dart';
import 'order_tracking_page.dart';

export 'order_tracking_page.dart';

/// Legacy alias for [OrderTrackingPage] providing backwards-compatibility
/// while consolidating all delivery tracking into a single unified screen.
class TrackingPage extends StatelessWidget {
  final String? trackingId;

  const TrackingPage({super.key, this.trackingId});

  @override
  Widget build(BuildContext context) {
    return OrderTrackingPage(
      trackingId: trackingId,
      orderId: trackingId,
    );
  }
}
