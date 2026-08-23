import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../core/auth/session_provider.dart';
import '../core/auth/user_role.dart';

import '../widgets/brand_logo.dart';
import 'booking_page.dart';
import 'payment_page.dart';
import 'marketplace/public_marketplace_page.dart';
import 'request_delivery_page.dart';
import 'receive_goods_stage.dart';
import 'operations/gate_pass_page.dart';
import 'copilot_page.dart';
import 'smart_inventory_stage.dart';
import 'login.dart';
import 'registration_page.dart';

import '../services/marketplace_service.dart';
import '../models/history_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MarketplaceService _marketService = MarketplaceService();
  late Future<List<DashboardActivity>> _activityFuture;

  Map<String, dynamic> _stats = {
    'shelves': 0,
    'items': 0,
    'pendingOrders': 0,
    'totalValue': 0.0,
    'activeRentals': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    MarketplaceService.updateNotifier.addListener(_refreshData);
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_refreshData);
    super.dispose();
  }

  void _refreshData() => _loadData();

  Future<void> _loadData() async {
    setState(() {
      _activityFuture = _marketService.getRecentActivity();
    });
    final stats = await _marketService.getDashboardStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = SessionProvider.of(context);
    final isGuest = session.role == UserRole.guest;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: isGuest
          ? null
          : FloatingActionButton(
              heroTag: 'home_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CopilotPage()),
              ),
              backgroundColor: AppColors.bluePrimary,
              elevation: 3,
              child: const Icon(Icons.support_agent_outlined, size: 26, color: Colors.white),
            ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.bluePrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(l10n, isGuest),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isGuest) ...[
                      _buildGuestStatsPlaceholder(context),
                      const SizedBox(height: 16),
                      _buildGuestPromoBanner(context),
                      const SizedBox(height: 16),
                      _buildGuestPublicStats(context),
                      const SizedBox(height: 16),
                      _buildGuestCTA(context),
                    ] else ...[
                      _buildStatsOverview(l10n),
                      _buildAlertsSection(l10n),
                      const SizedBox(height: 16),
                      _buildWarehousePrep(context, l10n),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, l10n),
                      const SizedBox(height: 16),
                      _buildActiveRentals(l10n),
                      const SizedBox(height: 16),
                      _buildRecentActivitySection(l10n),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n, bool isGuest) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 60, 24, isGuest ? 28 : 54),
      decoration: const BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BrandLogo(height: 36, isLight: true),
              Row(
                children: [
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) {
                      final isAr = localeProvider.locale.languageCode == 'ar';
                      return InkWell(
                        onTap: () => localeProvider.toggleLocale(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'EN' : 'العربية',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (!isGuest) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (isGuest)
            _buildGuestHeaderContent(context)
          else
            Consumer<UserProvider>(
              builder: (context, user, _) {
                final isArHeader = Localizations.localeOf(context).languageCode == 'ar';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArHeader ? 'أهلاً بك، ${user.displayName}' : 'Hello, ${user.displayName}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArHeader
                          ? 'إليك ملخص النشاط لهذا اليوم.'
                          : "Here's what's happening today.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGuestHeaderContent(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'مرحباً بك في NXN' : 'Welcome to NXN',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'المنصة الأولى للخدمات اللوجستية والتخزين في الإمارات.' : 'UAE\'s leading logistics & warehousing platform.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const LoginPage())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isAr ? 'تسجيل الدخول' : 'Sign In',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegistrationPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isAr ? 'إنشاء حساب' : 'Register',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── GUEST-ONLY SECTIONS ─────────────────────────────────────────────────────

  Widget _buildGuestStatsPlaceholder(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Row(
        children: [
          _buildLockedStatCard(
            title: isAr ? 'إجمالي الأرفف' : 'Total Shelves',
            icon: Icons.shelves,
            color: AppColors.bluePrimary,
          ),
          const SizedBox(width: 16),
          _buildLockedStatCard(
            title: isAr ? 'قيمة المخزون' : 'Stock Value',
            icon: Icons.monetization_on_rounded,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedStatCard(
      {required String title, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003C8E).withValues(alpha: 0.05),
              blurRadius: 12,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blueGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.blueMid, size: 18),
                ),
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.blueLight),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.blueGlow,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestPromoBanner(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bluePrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003C8E).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warehouse_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'ابدأ الآن مع NXN اللوجستية' : 'Get Started with NXN Logistics',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'تخزين وإدارة وشحن المنتجات عبر الإمارات.' : 'Store, manage, and ship products across the UAE.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPublicStats(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final stats = [
      {'label': isAr ? 'المستودعات' : 'Warehouses', 'value': '4', 'icon': Icons.warehouse_outlined},
      {'label': isAr ? 'المدن' : 'Cities', 'value': isAr ? 'كافة الإمارات' : 'UAE-wide', 'icon': Icons.location_on_outlined},
      {'label': isAr ? 'التجار' : 'Merchants', 'value': '500+', 'icon': Icons.storefront_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'لمحة عن المنصة' : 'Platform at a Glance',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: stats.map((s) {
              return Column(
                children: [
                  Icon(s['icon'] as IconData,
                      color: AppColors.bluePrimary, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    s['value'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    s['label'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCTA(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationPage()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bluePrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded,
            color: Colors.white, size: 20),
        label: Text(
          isAr ? 'إنشاء حساب تاجر مجاني' : 'Create a Free Merchant Account',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ─── MERCHANT SECTIONS ───────────────────────────────────────────────────────

  Widget _buildStatsOverview(AppLocalizations l10n) {
    final double val =
        (_stats['totalValue'] as num?)?.toDouble() ?? 0.0;
    final String valStr = val >= 1000
        ? '${(val / 1000).toStringAsFixed(1)}k'
        : val.toStringAsFixed(0);
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Row(
        children: [
          _buildStatCard(
            title: l10n.totalShelves,
            value: '${_stats['shelves']}',
            icon: Icons.shelves,
            color: AppColors.bluePrimary,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            title: l10n.stockValue,
            value: 'AED $valStr',
            icon: Icons.monetization_on_rounded,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003C8E).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blueGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.bluePrimary, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(AppLocalizations l10n) {
    final lowStock = _stats['lowStock'] as int? ?? 0;
    final outOfStock = _stats['outOfStock'] as int? ?? 0;
    if (lowStock == 0 && outOfStock == 0) return const SizedBox.shrink();
    return Row(
      children: [
        if (lowStock > 0)
          Expanded(
            child: _buildAlertChip(
              label: l10n.lowStockCount(lowStock),
              icon: Icons.warning_amber_rounded,
              color: Colors.amber,
              bgColor: Colors.amber.shade50,
            ),
          ),
        if (lowStock > 0 && outOfStock > 0) const SizedBox(width: 12),
        if (outOfStock > 0)
          Expanded(
            child: _buildAlertChip(
              label: l10n.outOfStockCount(outOfStock),
              icon: Icons.error_outline_rounded,
              color: Colors.red,
              bgColor: Colors.red.shade50,
            ),
          ),
      ],
    );
  }

  Widget _buildAlertChip({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehousePrep(BuildContext context, AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ReceiveGoodsStagePageEN())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bluePrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003C8E).withValues(alpha: 0.20),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fact_check_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.warehousePrep,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAr ? 'إدارة واستلام الشحنات الواردة' : 'Manage incoming goods',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActionsTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildActionCard(
                title: l10n.gatePassTitle,
                icon: Icons.qr_code_2_rounded,
                color: const Color(0xFF2D3436),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GatePassPage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.bookSpace,
                icon: Icons.store_mall_directory_rounded,
                color: AppColors.bluePrimary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => BookingPage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.requestDeliveryAction,
                icon: Icons.local_shipping_rounded,
                color: Colors.purple,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RequestDeliveryPage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.myInventoryAction,
                icon: Icons.inventory_2_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SmartInventoryStageEN())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: isAr ? 'المتجر' : 'Marketplace',
                icon: Icons.storefront,
                color: Colors.green,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PublicMarketplacePage())),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                title: l10n.navPayments,
                icon: Icons.receipt_long_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaymentsPage())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.blueGlow,
        highlightColor: AppColors.blueGlow.withValues(alpha: 0.5),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blueGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.bluePrimary, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRentals(AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final List<dynamic> rentals =
        _stats['activeRentals'] as List<dynamic>? ?? [];

    // Aggregate active shelves per unique warehouse branch name
    final Map<String, int> aggregatedWarehouses = {};
    for (var rental in rentals) {
      final String rawName = rental['warehouse'] ?? 'Unknown Branch';
      final int count = (rental['shelves'] is num) ? (rental['shelves'] as num).toInt() : 0;
      if (count <= 0) continue; // Skip 0 shelf entries

      String branchName = rawName;
      if (isAr) {
        if (branchName == 'aln' || branchName.toLowerCase().contains('al ain') || branchName.contains('العين')) {
          branchName = 'مستودع العين المركزي';
        } else if (branchName == 'dxb' || branchName.toLowerCase().contains('dubai') || branchName.contains('دبي')) {
          branchName = 'مستودع دبي المركزي';
        } else if (branchName == 'auh' || branchName.toLowerCase().contains('abu dhabi') || branchName.contains('أبوظبي')) {
          branchName = 'مستودع أبوظبي المركزي';
        } else if (branchName == 'shj' || branchName.toLowerCase().contains('sharjah') || branchName.contains('الشارقة')) {
          branchName = 'مستودع الشارقة الإقليمي';
        }
      } else {
        if (branchName == 'aln' || branchName.contains('العين')) {
          branchName = 'Al Ain Central Warehouse';
        } else if (branchName == 'dxb' || branchName.contains('دبي')) {
          branchName = 'Dubai Central Warehouse';
        } else if (branchName == 'auh' || branchName.contains('أبوظبي')) {
          branchName = 'Abu Dhabi Central Warehouse';
        } else if (branchName == 'shj' || branchName.contains('الشارقة')) {
          branchName = 'Sharjah Regional Hub';
        }
      }

      aggregatedWarehouses[branchName] = (aggregatedWarehouses[branchName] ?? 0) + count;
    }

    if (aggregatedWarehouses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blueGlow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.warehouse_outlined, size: 32, color: AppColors.blueMid),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا توجد تأجيرات مساحة نشطة.' : 'No active space rentals.',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BookingPage())),
                child: Text(l10n.bookSpace),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...aggregatedWarehouses.entries.map((entry) {
          final String branchName = entry.key;
          final int totalShelves = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blueGlow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warehouse_outlined,
                      color: AppColors.bluePrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branchName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(l10n.activeShelves(totalShelves),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.blueGlow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.blueLight.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    l10n.managingTag,
                    style: const TextStyle(
                        color: AppColors.bluePrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentActivitySection(AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentActivity,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () {},
              child: Text(isAr ? 'عرض الكل' : 'View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<DashboardActivity>>(
          future: _activityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(l10n.failedToLoadHistory,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              );
            }
            final activities = snapshot.data ?? [];
            if (activities.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(l10n.noRecentActivity,
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(
                  context: context,
                  activity: activity,
                  time: _formatDate(activity.date, l10n),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final hours = diff.inHours.abs();
    final minutes = diff.inMinutes.abs();
    final days = diff.inDays.abs();

    if (days == 0) {
      if (hours == 0) return l10n.minutesAgo(minutes);
      return l10n.hoursAgo(hours);
    }
    if (days == 1) return l10n.yesterday;
    if (days < 7) return l10n.daysAgo(days);
    return DateFormat('d MMMM', l10n.localeName).format(date);
  }

  Widget _buildActivityItem({
    required BuildContext context,
    required DashboardActivity activity,
    required String time,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final displayTitle = activity.getDisplayTitle(isAr);
    final displaySubtitle = activity.getDisplaySubtitle(isAr);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.blueGlow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon, color: AppColors.blueMid, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.blueLight,
            ),
          ),
        ],
      ),
    );
  }
}