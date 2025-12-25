import 'package:flutter/material.dart';
import '../../theme.dart';
import 'admin/admin_login_page.dart';
import 'booking_page.dart';
import 'marketplace/seller_hub.dart';
import 'operations/gate_pass_page.dart';
import 'operations/tracking_page.dart';
import 'onboarding/service_overview_page.dart';

class DemoMenuPage extends StatelessWidget {
  const DemoMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Features & Demo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF3F6FB),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _Header('Core User Experience'),
          _DemoTile(
            title: 'Customer Dashboard',
            subtitle: 'Main entry point for users',
            icon: Icons.dashboard_rounded,
            // Navigate back to home if user came from there, effectively "switching"
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
          _DemoTile(
            title: 'Onboarding / Service Overview',
            subtitle: 'First screen users see',
            icon: Icons.view_carousel_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceOverviewPage())),
          ),
          _DemoTile(
            title: 'Booking Flow',
            subtitle: 'New storage booking',
            icon: Icons.add_shopping_cart,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
          ),

          const SizedBox(height: 24),
          const _Header('New Features'),
           _DemoTile(
            title: 'Gate Pass (QR)',
            subtitle: 'Entry QRCode for warehouse',
            icon: Icons.qr_code_2_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassPage())),
          ),
          _DemoTile(
            title: 'Shipment Tracking',
            subtitle: 'Live map tracking simulation',
            icon: Icons.map_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPage())),
          ),

          const SizedBox(height: 24),
          const _Header('Business / Operations'),
          _DemoTile(
            title: 'Seller Hub',
            subtitle: 'Marketplace management',
            icon: Icons.storefront_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerHub())),
          ),

          const SizedBox(height: 24),
          const _Header('Admin / Warehouse Staff'),
          _DemoTile(
            title: 'Admin Portal Login',
            subtitle: 'Switch to Tablet View (Pin: 8818)',
            icon: Icons.admin_panel_settings_rounded,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage())),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}

class _DemoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color = AppColors.bluePrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
             color: color.withValues(alpha: 0.1),
             shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}
