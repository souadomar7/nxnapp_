import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/merchant_data_provider.dart';
import '../l10n/app_localizations.dart';
import '../core/auth/session_provider.dart';
import '../core/auth/user_role.dart';
import '../widgets/brand_logo.dart';
import '../widgets/sync_status_badge.dart';

// Screens
import 'booking_page.dart';
import 'payment_page.dart';
import 'create_shipment_page.dart';
import 'request_delivery_page.dart';
import 'operations/gate_pass_page.dart';
import 'operations/order_tracking_page.dart';
import 'copilot_page.dart';
import 'smart_inventory_stage.dart';
import 'marketplace/seller_hub.dart';
import 'marketplace/add_product_page.dart';
import 'marketplace/seller_orders_page.dart';
import 'profile/wallet_page.dart';
import 'notifications_page.dart';
import 'login.dart';
import 'registration_page.dart';
import 'marketplace/public_marketplace_page.dart';

// Models
import '../models/history_models.dart';
import '../core/utils/localization_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _activityFilter = 'all'; // 'all', 'orders', 'invoices'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final session = SessionProvider.of(context);
    final isGuest = session.role == UserRole.guest;
    final merchantData = context.watch<MerchantDataProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => context.read<MerchantDataProvider>().refreshDashboard(force: true),
        color: AppColors.bluePrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Clean Modern Header
              _buildHeader(context, l10n, isGuest, isAr),

              // 2. Main Dashboard Body with Structured Hierarchy
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isGuest) ...[
                      _buildGuestHero(context, isAr),
                      const SizedBox(height: 18),
                      _buildGuestCTA(context, isAr),
                    ] else ...[
                      // KPI Stat Grid (Sleek 2x2 - Connected to Central Merchant Provider)
                      _buildKpiGrid(context, l10n, isAr, merchantData),
                      const SizedBox(height: 18),

                      // Consolidated Command Center (Store + Intake + Actions)
                      _buildMerchantCommandCenter(context, l10n, isAr),
                      const SizedBox(height: 18),

                      // Curated 4-Action Grid
                      _buildQuickActionGrid(context, l10n, isAr),
                      const SizedBox(height: 22),

                      // Active Warehouse Leases (Visual Component - Reactive Subscriptions)
                      _buildActiveWarehouseLeases(context, l10n, isAr, merchantData),
                      const SizedBox(height: 22),

                      // Inline AI Assistant (Replaces Obtrusive FAB)
                      _buildInlineAssistantBanner(context, isAr),
                      const SizedBox(height: 22),

                      // Smart Filtered Activity & Consolidated Financial Overview
                      _buildRecentActivitySection(context, l10n, isAr, merchantData),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. CLEAN HEADER (Hero Section)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isGuest, bool isAr) {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(20, MediaQuery.of(context).padding.top + 14, 20, isGuest ? 24 : 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Logo & Actions (Language, AI, Notifications)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandLogo(height: 32, isLight: true),
              Row(
                children: [
                  const SyncStatusBadge(),
                  const SizedBox(width: 8),

                  // Language Switcher Pill
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) {
                      return InkWell(
                        onTap: () => localeProvider.toggleLocale(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'English' : 'العربية',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // AI Copilot Header Quick Launcher
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CopilotPage()),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                    ),
                  ),

                  if (!isGuest) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Merchant Greeting & Status Badge
          if (isGuest) ...[
            Text(
              isAr ? 'مرحباً بك في NXN' : 'Welcome to NXN Logistics',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAr ? 'منصة التخزين الذكي وإدارة سلاسل الإمداد في الإمارات' : 'Smart warehousing & logistics hub across the UAE',
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ] else
            Consumer<UserProvider>(
              builder: (context, user, _) {
                final name = user.displayName.isNotEmpty ? user.displayName : 'Merchant';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isAr ? 'أهلاً بك، $name' : 'Welcome back, $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAr ? 'تاجر معتمد • نشط' : 'Active Vendor • Verified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. GLANCEABLE KPI GRID (Connected to Central MerchantDataProvider)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildKpiGrid(BuildContext context, AppLocalizations l10n, bool isAr, MerchantDataProvider data) {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Column(
        children: [
          Row(
            children: [
              // Card 1: Active Shelves
              Expanded(
                child: _KpiCard(
                  title: isAr ? 'الأرفف النشطة' : 'Active Shelves',
                  value: '${data.totalShelves} ${isAr ? "رف" : "Shelves"}',
                  subtitle: isAr ? 'عبر ${data.activeHubsCount} مستودعات' : 'across ${data.activeHubsCount} Hubs',
                  icon: Icons.shelves,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFEFF6FF),
                  progressBarValue: (data.totalShelves / 30.0).clamp(0.1, 1.0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SmartInventoryStageEN()),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Card 2: Total Inventory Value
              Expanded(
                child: _KpiCard(
                  title: isAr ? 'قيمة المخزون' : 'Stock Value',
                  value: 'AED ${data.formattedStockValue}',
                  subtitle: isAr ? 'إجمالي الأصول' : 'Total asset value',
                  icon: Icons.monetization_on_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFECFDF5),
                  trendText: '+12.4%',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SmartInventoryStageEN()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Card 3: Pending Orders / Shipments
              Expanded(
                child: _KpiCard(
                  title: isAr ? 'طلبات التجهيز' : 'To Dispatch',
                  value: '${data.pendingOrdersCount} ${isAr ? "طلبات" : "Orders"}',
                  subtitle: data.pendingOrdersCount > 0
                      ? (isAr ? 'يتطلب التنفيذ الفوري' : 'Action required')
                      : (isAr ? 'جميع الطلبات منجزة' : 'All caught up'),
                  icon: Icons.local_shipping_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFFFBEB),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SellerOrdersPage()),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Card 4: Settlement Wallet
              Expanded(
                child: _KpiCard(
                  title: isAr ? 'محفظة الأرباح' : 'Wallet Balance',
                  value: 'AED ${data.formattedWalletBalance}',
                  subtitle: isAr ? 'سحب الرصيد ›' : 'Withdraw funds ›',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFFF5F3FF),
                  isActionSubtitle: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletPage()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. CONSOLIDATED MERCHANT COMMAND CENTER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMerchantCommandCenter(BuildContext context, AppLocalizations l10n, bool isAr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.bluePrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'مركز قيادة التاجر' : 'Merchant Command Center',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr ? 'إدارة المنتجات، الأسعار، وتوريد البضائع' : 'Store catalog, price editing & dock intake',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddProductPage()),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      isAr ? 'إضافة منتج' : 'Add Product',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerHub()),
                    ),
                    icon: const Icon(Icons.dashboard_outlined, size: 17, color: AppColors.bluePrimary),
                    label: Text(
                      isAr ? 'لوحة المتجر' : 'Seller Hub',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.bluePrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.bluePrimary.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. CURATED 4-ACTION QUICK GRID (Strictly Merchant Focused)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionGrid(BuildContext context, AppLocalizations l10n, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الإجراءات اللوجستية السريعة' : 'Quick Operations',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            // 1. Book Shelf Space
            _ActionTile(
              title: isAr ? 'حجز مساحة رفوف' : 'Book Shelf Space',
              subtitle: isAr ? '100 درهم/رف/شهر' : 'AED 100/shelf/mo',
              icon: Icons.warehouse_outlined,
              accentColor: const Color(0xFF2563EB),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookingPage()),
              ),
            ),

            // 2. Inbound Drop-off
            _ActionTile(
              title: isAr ? 'توريد بضائع' : 'Inbound Drop-off',
              subtitle: isAr ? 'شحنات للمستودع' : 'Deliver to warehouse',
              icon: Icons.move_to_inbox_outlined,
              accentColor: const Color(0xFF059669),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateShipmentPage()),
              ),
            ),

            // 3. Request Outbound Dispatch
            _ActionTile(
              title: isAr ? 'طلب شحن خارجي' : 'Outbound Dispatch',
              subtitle: isAr ? 'توصيل للمشتري' : 'Ship to customer',
              icon: Icons.local_shipping_outlined,
              accentColor: const Color(0xFF7C3AED),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestDeliveryPage()),
              ),
            ),

            // 4. Generate Gate Pass
            _ActionTile(
              title: isAr ? 'تصريح الدخول' : 'Dock Gate Pass',
              subtitle: isAr ? 'رمز QR للشاحنة' : 'QR driver admission',
              icon: Icons.qr_code_scanner_rounded,
              accentColor: const Color(0xFF0F172A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GatePassPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 5. ACTIVE WAREHOUSE LEASES (Dynamic Subscription Cards)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildActiveWarehouseLeases(BuildContext context, AppLocalizations l10n, bool isAr, MerchantDataProvider data) {
    final leases = data.activeSubscriptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr ? 'المستودعات المؤجرة النشطة' : 'Active Warehouse Leases',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookingPage()),
              ),
              child: Text(
                isAr ? '+ إضافة مساحة' : '+ Add Space',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.bluePrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (leases.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shelves, color: AppColors.bluePrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'لا توجد مساحات مؤجرة بعد' : 'No active warehouse leases',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr ? 'اضغط "+ إضافة مساحة" لحجز رفوف بمستودعات NXN' : 'Tap "+ Add Space" to book shelf space in NXN hubs',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...leases.map((lease) {
          final name = lease.displayName(isAr);
          final shelfCount = lease.shelvesCount;
          final occupancyPercent = lease.occupancyPercent;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warehouse_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              '$shelfCount ${isAr ? "أرفف" : "Shelves"}',
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: occupancyPercent,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  occupancyPercent > 0.8 ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(occupancyPercent * 100).toInt()}% ${isAr ? "ممتلئ" : "Full"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 6. INLINE AI ASSISTANT BANNER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildInlineAssistantBanner(BuildContext context, bool isAr) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CopilotPage()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF38BDF8), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'تحتاج مساعدة؟ اسأل وكيل NXN الذكي' : 'Need help? Ask NXN AI Agent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr ? 'إرشادات فورية لحجز المساحات والشحن والطلبات' : 'Instant guidance for warehouse intake & shipping',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 7. SMART FILTERED ACTIVITY & CONSOLIDATED FINANCIALS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildRecentActivitySection(BuildContext context, AppLocalizations l10n, bool isAr, MerchantDataProvider data) {
    final activities = data.recentActivities;
    final pendingCount = data.pendingInvoicesCount;
    final pendingTotal = data.pendingInvoicesTotal;

    // Filter activities
    List<DashboardActivity> filtered = activities;
    if (_activityFilter == 'orders') {
      filtered = activities.where((a) => a.type == ActivityType.delivery || a.title.contains('Order')).toList();
    } else if (_activityFilter == 'invoices') {
      filtered = activities.where((a) => a.type == ActivityType.invoice).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr ? 'النشاط والمعاملات' : 'Activity & Orders',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            // Filter Pills [All, Orders, Invoices]
            Row(
              children: [
                _FilterChip(
                  label: isAr ? 'الكل' : 'All',
                  isSelected: _activityFilter == 'all',
                  onTap: () => setState(() => _activityFilter = 'all'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: isAr ? 'الطلبات' : 'Orders',
                  isSelected: _activityFilter == 'orders',
                  onTap: () => setState(() => _activityFilter = 'orders'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: isAr ? 'الفواتير' : 'Invoices',
                  isSelected: _activityFilter == 'invoices',
                  onTap: () => setState(() => _activityFilter = 'invoices'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (data.isLoading) ...[
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ] else if (activities.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                isAr ? 'لا يوجد نشاط مسجل مؤخراً' : 'No recent activities recorded',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ),
        ] else ...[
          // Consolidated Invoice Summary Card
          if (pendingCount > 1 && (_activityFilter == 'all' || _activityFilter == 'invoices'))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? '$pendingCount فواتير بانتظار السداد'
                              : '$pendingCount Invoices Pending Payment',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAr
                              ? '${pendingTotal.toStringAsFixed(2)} درهم إجمالي المستحق'
                              : 'AED ${pendingTotal.toStringAsFixed(2)} Total Outstanding',
                          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentsPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isAr ? 'مراجعة وسداد' : 'Review & Pay',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Clean Feed Items
          ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: filtered.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = filtered[i];
              final isOrder = item.type == ActivityType.delivery || item.title.contains('Order');
              final isPending = item.subtitle.contains('PENDING');

              return InkWell(
                onTap: () {
                  if (isOrder) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderTrackingPage()),
                    );
                  } else if (item.type == ActivityType.invoice) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentsPage()),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOrder ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isOrder ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isOrder
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF2563EB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isOrder ? Icons.shopping_bag_rounded : item.icon,
                          color: isOrder ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.getDisplayTitle(isAr),
                              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isOrder ? const Color(0xFF065F46) : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.getDisplaySubtitle(isAr),
                              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 11,
                                color: isOrder ? const Color(0xFF047857) : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            LocalizationUtils.formatRelativeTime(item.date, l10n: l10n, isArabic: isAr),
                            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          if (isPending) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAr ? 'معلق' : 'PENDING',
                                style: const TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 8. GUEST MODE PLACEHOLDERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildGuestHero(BuildContext context, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.bluePrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? 'سوق NXN للشركات والتجار' : 'NXN SME Marketplace Hub',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'استأجر رفوف تخزين، اعرض منتجاتك للبيع، ونفذ شحناتك اللوجستية بكل سهولة.'
                : 'Rent flexible shelf spaces, list products for sale, and dispatch orders effortlessly.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PublicMarketplacePage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? 'تصفح السوق العام' : 'Explore Public Marketplace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCTA(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            isAr ? 'انضم إلى شبكة التجار المعتمدين' : 'Join Verified Merchant Network',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            isAr ? 'سجل عبر الهوية الرقمية UAE PASS واستفد من حلول التخزين الفوري.' : 'Register with UAE PASS and start renting warehouse shelves today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isAr ? 'تسجيل الدخول' : 'Sign In'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationPage())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isAr ? 'إنشاء حساب' : 'Register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// REUSABLE STAT & ACTION SUBCOMPONENTS
// ════════════════════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final double? progressBarValue;
  final String? trendText;
  final bool isActionSubtitle;
  final VoidCallback onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.progressBarValue,
    this.trendText,
    this.isActionSubtitle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                if (trendText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trendText!,
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            if (progressBarValue != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progressBarValue,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActionSubtitle ? FontWeight.bold : FontWeight.w500,
                color: isActionSubtitle ? AppColors.bluePrimary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bluePrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.bluePrimary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}