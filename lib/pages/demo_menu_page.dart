import 'package:flutter/material.dart';
import 'booking_page.dart';
import 'marketplace/seller_hub.dart';
import 'marketplace/public_marketplace_page.dart';
import 'operations/gate_pass_page.dart';
import 'operations/tracking_page.dart';
import 'onboarding/service_overview_page.dart';
import 'admin_panel_page.dart';
import 'qr_scanner_page.dart';
import 'smart_inventory_stage.dart';
import 'receive_goods_stage.dart';
import 'request_delivery_page.dart';
import 'copilot_page.dart';
import 'profile/my_subscriptions_page.dart';
import 'profile/wallet_page.dart';
import 'settings/kyc_page.dart';
import 'settings/notification_settings_page.dart';
import 'payment_page.dart';
import 'terms_and_conditions.dart';

class DemoMenuPage extends StatelessWidget {
  const DemoMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'خريطة كافة الشاشات والخصائص' : 'All App Pages & Features'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF3F6FB),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 1. CORE MARKETPLACE & E-COMMERCE ─────────────────────────────
          _Header(isAr ? '1. السوق والتجارة الإلكترونية' : '1. Public Marketplace & E-Commerce'),
          _DemoTile(
            title: isAr ? 'السوق المعتمد العام' : 'Public Verified Marketplace',
            subtitle: isAr ? 'تصفح المنتجات والشراء المباشر' : 'Browse products, search, filter & buyer checkout',
            icon: Icons.storefront_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicMarketplacePage())),
          ),
          _DemoTile(
            title: isAr ? 'مركز إدارة التاجر' : 'Merchant Seller Hub',
            subtitle: isAr ? 'إحصائيات المبيعات، المخزون وتوثيق المتجر' : 'Store stats, inventory linked products & approval state',
            icon: Icons.store_mall_directory_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerHub())),
          ),

          const SizedBox(height: 20),

          // ── 2. WAREHOUSE & OPERATIONS ────────────────────────────────────
          _Header(isAr ? '2. المستودعات والعمليات اللوجستية' : '2. Warehouse Operations & WMS'),
          _DemoTile(
            title: isAr ? 'لوحة الإدارة العليا' : 'Super Admin & Ops Control Panel',
            subtitle: isAr ? 'إشراف الشحنات الواردة، التوصيل، التراخيص والسحوبات' : 'Inbound STO, Outbound WAY, KYC approvals & Hub holds',
            icon: Icons.admin_panel_settings_rounded,
            color: const Color(0xFF1E293B),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelPage())),
          ),
          _DemoTile(
            title: isAr ? 'ماسح التصاريح والباركوود' : 'QR Gate Pass & Barcode Scanner',
            subtitle: isAr ? 'فحص الكاميرا لتصاريح STO وبوالص WAY' : 'Camera scanner for STO-XXXXXX & WAY-XXXXXX',
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFF059669),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerPage())),
          ),
          _DemoTile(
            title: isAr ? 'منصة المخزون الذكي WMS' : 'Smart Inventory Stage WMS',
            subtitle: isAr ? 'تتبع الأرفف والكميات والرسم البياني' : 'Shelf tracking, SKU breakdown & distribution charts',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartInventoryStageEN())),
          ),
          _DemoTile(
            title: isAr ? 'جدولة شحنة واردة' : 'Schedule Inbound Drop-off',
            subtitle: isAr ? 'حجز رصيف التفريغ وإصدار تصريح STO' : '4-step wizard, temp modes & STO Gate Pass',
            icon: Icons.move_to_inbox_rounded,
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveGoodsStagePageEN())),
          ),
          _DemoTile(
            title: isAr ? 'طلب توصيل وخروج شحنة' : 'Request Outbound Delivery',
            subtitle: isAr ? 'اختيار شركة الشحن وإصدار بوليصة WAY' : 'Domestic/GCC shipping, couriers & WAY waybill',
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestDeliveryPage())),
          ),
          _DemoTile(
            title: isAr ? 'استئجار مساحة رفوف' : 'Rent Warehouse Space',
            subtitle: isAr ? 'اختيار المستودع وتحديد الرفوف' : 'Browse hubs, shelf allocation & booking',
            icon: Icons.add_shopping_cart_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingPage())),
          ),

          const SizedBox(height: 20),

          // ── 3. AI & DIGITAL PASSES ───────────────────────────────────────
          _Header(isAr ? '3. المساعد الذكي والتتبع الرقمي' : '3. AI Assistant & Digital Passes'),
          _DemoTile(
            title: isAr ? 'المساعد الذكي NXN Copilot' : 'AI Logistics Copilot',
            subtitle: isAr ? 'مساعد التخزين والخدمات اللوجستية' : 'AI Chatbot for warehousing & fulfillment queries',
            icon: Icons.support_agent_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CopilotPage())),
          ),
          _DemoTile(
            title: isAr ? 'تتبع الشحنات المباشر' : 'Live Shipment Tracking',
            subtitle: isAr ? 'تتبع حركة السائق على الخريطة' : 'Real-time GPS delivery tracking simulation',
            icon: Icons.map_rounded,
            color: const Color(0xFF059669),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPage())),
          ),
          _DemoTile(
            title: isAr ? 'تصريح الدخول الرقمي' : 'Digital Gate Pass QR',
            subtitle: isAr ? 'رمز QR لدخول المستودع' : 'Digital entry pass for warehouse guards',
            icon: Icons.qr_code_2_rounded,
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassPage())),
          ),

          const SizedBox(height: 20),

          // ── 4. ACCOUNT, FINANCIALS & SETTINGS ───────────────────────────
          _Header(isAr ? '4. الحساب، المالية والإعدادات' : '4. Account, Financials & Settings'),
          _DemoTile(
            title: isAr ? 'الاشتراكات النشطة' : 'My Active Subscriptions',
            subtitle: isAr ? 'عرض المساحات المؤجرة والأرفف' : 'Leased shelf spaces & renewal dates',
            icon: Icons.subscriptions_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySubscriptionsPage())),
          ),
          _DemoTile(
            title: isAr ? 'الفواتير والمحفظة' : 'Invoices & Merchant Wallet',
            subtitle: isAr ? 'رصيد الأرباح وتصدير فواتير PDF' : 'Balances, payouts & PDF invoice exports',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF059669),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
          ),
          _DemoTile(
            title: isAr ? 'الدفع الإلكتروني' : 'Payments & Invoices',
            subtitle: isAr ? 'دفع رسوم الشحن والاستئجار' : 'Pay invoices & view PDF receipts',
            icon: Icons.payment_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsPage())),
          ),
          _DemoTile(
            title: isAr ? 'توثيق الرخصة التجاري (KYC)' : 'KYC Trade License Upload',
            subtitle: isAr ? 'رفع مستندات التوثيق للإدارة' : 'Submit trade license for admin approval',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KYCPage())),
          ),
          _DemoTile(
            title: isAr ? 'إعدادات الإشعارات' : 'Notification Preferences',
            subtitle: isAr ? 'تنبيهات الشحنات والطلبات' : 'Push notifications & system alerts settings',
            icon: Icons.notifications_rounded,
            color: const Color(0xFF64748B),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage())),
          ),
          _DemoTile(
            title: isAr ? 'الشروط والأحكام' : 'Terms & Conditions',
            subtitle: isAr ? 'سياسات التخزين والخدمة' : 'Logistics, warehousing & privacy policies',
            icon: Icons.gavel_rounded,
            color: const Color(0xFF64748B),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsPage())),
          ),
          _DemoTile(
            title: isAr ? 'نظرة عامة على الخدمة' : 'Service Overview & Onboarding',
            subtitle: isAr ? 'الشاشة التعريفية للخدمة' : 'Introduction onboarding carousel',
            icon: Icons.view_carousel_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceOverviewPage())),
          ),

          const SizedBox(height: 30),
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
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
      ),
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
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
