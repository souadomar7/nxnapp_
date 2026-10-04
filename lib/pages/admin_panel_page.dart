import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/marketplace_service.dart';
import '../models/history_models.dart';
import 'qr_scanner_page.dart';
import 'admin/payout_settlement_page.dart';

class AdminPanelColors {
  static const primary = Color(0xFF1E293B); // Dark Slate Blue for Executive Admin
  static const background = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textSub = Color(0xFF64748B);
  static const cardBorder = Color(0xFFE2E8F0);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
  static const accentWarning = Color(0xFFF59E0B);
  static const accentPurple = Color(0xFF8B5CF6);
}

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceService _marketplaceService = MarketplaceService();

  List<DashboardActivity> _activities = [];

  // Pending seller approvals (clean fresh state)
  final List<Map<String, String>> _pendingSellers = [];
  final List<Map<String, dynamic>> _quarantineItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAdminData();
    MarketplaceService.updateNotifier.addListener(_loadAdminData);
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_loadAdminData);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final list = await _marketplaceService.getRecentActivity(limit: 20);
    final List<Map<String, String>> loadedPending = [];

    // 1. Fetch unverified sellers from Supabase sme_sellers
    try {
      final List<dynamic> unverifiedSellers = await Supabase.instance.client
          .from('sme_sellers')
          .select()
          .eq('is_verified', false)
          .order('created_at', ascending: false);

      for (var s in unverifiedSellers) {
        final id = s['id']?.toString() ?? '';
        final shop = s['business_name']?.toString() ?? 'New Merchant';
        final phone = s['contact_number']?.toString() ?? '';
        final license = s['license_number']?.toString() ?? 'Pending Upload';
        loadedPending.add({
          'id': id,
          'seller_id': id,
          'shop': shop,
          'owner': phone.isNotEmpty ? phone : 'Merchant Owner',
          'emirate': 'UAE',
          'license': license,
          'trn': '100-${id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}',
          'source': 'sme_sellers',
        });
      }
    } catch (e) {
      debugPrint('Error loading unverified sme_sellers: $e');
    }

    // 2. Fetch unapproved shops from Supabase marketplace_shops
    try {
      final List<dynamic> unapprovedShops = await Supabase.instance.client
          .from('marketplace_shops')
          .select()
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      for (var s in unapprovedShops) {
        final id = s['id']?.toString() ?? '';
        final sellerId = s['seller_id']?.toString() ?? id;
        if (loadedPending.any((p) => p['id'] == id || p['seller_id'] == sellerId)) continue;
        loadedPending.add({
          'id': id,
          'seller_id': sellerId,
          'shop': s['shop_name']?.toString() ?? 'Merchant Shop',
          'owner': s['license_name']?.toString() ?? 'Commercial License',
          'emirate': 'Dubai',
          'license': s['license_name']?.toString() ?? 'CN-2891048',
          'trn': '100-${id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}',
          'source': 'marketplace_shops',
        });
      }
    } catch (e) {
      debugPrint('Error loading unapproved shops: $e');
    }

    // 3. Check SharedPreferences for locally pending registrations
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingId = prefs.getString('pending_seller_id');
      final isVerified = prefs.getBool('is_verified_${pendingId ?? ""}') ?? false;
      final isMerchantPending = prefs.getBool('is_merchant_pending') ?? false;

      if (pendingId != null && !isVerified && isMerchantPending) {
        if (!loadedPending.any((p) => p['id'] == pendingId || p['seller_id'] == pendingId)) {
          loadedPending.add({
            'id': pendingId,
            'seller_id': pendingId,
            'shop': prefs.getString('pending_seller_name') ?? 'Pending Store',
            'owner': prefs.getString('pending_seller_contact') ?? 'Store Manager',
            'emirate': 'Dubai',
            'license': prefs.getString('pending_seller_license') ?? 'CN-2891048',
            'trn': '100-2938-4821',
            'source': 'local',
          });
        }
      }

      // 4. Also check UserProvider if user has pending account state
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final isUserVerified = prefs.getBool('merchant_verified') ?? false;
        if (!isUserVerified && isMerchantPending && currentUserId != null) {
          if (!loadedPending.any((p) => p['seller_id'] == currentUserId)) {
            loadedPending.add({
              'id': currentUserId,
              'seller_id': currentUserId,
              'shop': userProvider.displayName,
              'owner': userProvider.contactNumber,
              'emirate': 'Dubai',
              'license': userProvider.licenseNumber,
              'trn': '100-8849-2091',
              'source': 'user_provider',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking local pending approvals: $e');
    }

    if (mounted) {
      setState(() {
        _activities = list;
        _pendingSellers.clear();
        _pendingSellers.addAll(loadedPending);
      });
    }
  }

  Future<void> _approveSeller(int index, bool isAr) async {
    final seller = _pendingSellers[index];
    final shopName = seller['shop']!;
    final shopId = seller['id']!;
    final sellerId = seller['seller_id'] ?? shopId;

    // 1. Authorize & approve shop in MarketplaceService
    await _marketplaceService.verifyShop(shopId);

    // 2. Authorize in Supabase sme_sellers
    try {
      await Supabase.instance.client
          .from('sme_sellers')
          .update({'is_verified': true})
          .eq('id', sellerId);
    } catch (e) {
      debugPrint('Error updating sme_sellers is_verified: $e');
    }

    // 3. Authorize in Supabase marketplace_shops
    try {
      await Supabase.instance.client
          .from('marketplace_shops')
          .update({'is_approved': true})
          .eq('seller_id', sellerId);
    } catch (e) {
      debugPrint('Error updating marketplace_shops is_approved: $e');
    }

    // 4. Update SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_verified_$sellerId', true);
      await prefs.setBool('merchant_verified', true);
      await prefs.setBool('is_merchant_pending', false);
    } catch (e) {
      debugPrint('Error setting local prefs on approve: $e');
    }

    // 5. Update UserProvider if mounted
    if (mounted) {
      try {
        Provider.of<UserProvider>(context, listen: false).setVerified(true);
      } catch (_) {}
    }

    setState(() {
      _pendingSellers.removeAt(index);
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade800,
        content: Text(
          isAr
              ? 'تم اعتماد توثيق رخصة "$shopName" وتفويض التاجر رسمياً! 📜⚡'
              : 'Verified & authorized "$shopName" trade license! Store is now live 📜⚡',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AdminPanelColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── 1. Executive Admin Hero Header ─────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AdminPanelColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                tooltip: isAr ? 'ماسح التصاريح' : 'QR Gate Pass Scanner',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerPage()),
                  );
                },
              ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: Colors.amber,
                    ),
                    tooltip: isAr ? 'تبديل المظهر' : 'Toggle Dark Mode',
                    onPressed: () => themeProvider.toggleTheme(),
                  );
                },
              ),
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  return InkWell(
                    onTap: () => localeProvider.toggleLocale(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
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
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'لوحة تحكم كبار الإداريين' : 'Super Admin & Ops Panel',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr ? 'إدارة الشحنات الواردة، التوصيل، التراخيص والسحوبات' : 'Manage inbound drops, dispatching, KYC & seller payouts',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                isAr ? 'مسئول النظام 🛡️' : 'Super Admin 🛡️',
                                style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── 2. Top Executive Stats ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _adminStatCard(
                          title: isAr ? 'إجمالي الشحنات' : 'Total Logistics',
                          value: '${_activities.length}',
                          unit: isAr ? 'عملية' : 'Tickets',
                          icon: Icons.inventory_2_rounded,
                          color: AdminPanelColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _adminStatCard(
                          title: isAr ? 'طلبات التراخيص' : 'Pending KYC',
                          value: '${_pendingSellers.length}',
                          unit: isAr ? 'تجار' : 'Merchants',
                          icon: Icons.verified_user_rounded,
                          color: AdminPanelColors.accentWarning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _adminStatCard(
                          title: isAr ? 'إشغالات المستودعات' : 'Hub Occupancy',
                          value: '0%',
                          unit: isAr ? 'سعة' : 'Cap',
                          icon: Icons.warehouse_rounded,
                          color: AdminPanelColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _adminStatCard(
                          title: isAr ? 'سحوبات معلقة' : 'Pending Payouts',
                          value: 'AED 0.00',
                          unit: isAr ? 'مستحق' : 'IBAN Hold',
                          icon: Icons.account_balance_rounded,
                          color: AdminPanelColors.accentPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── 3. Navigation Tabs ───────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AdminPanelColors.primary,
                unselectedLabelColor: AdminPanelColors.textSub,
                indicatorColor: AdminPanelColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: isAr ? 'الشحنات الواردة 📥' : 'Inbound Drop-offs 📥'),
                  Tab(text: isAr ? 'طلبات التوصيل 🚚' : 'Outbound Orders 🚚'),
                  Tab(text: isAr ? 'اعتماد التراخيص 📜' : 'KYC Approvals 📜'),
                  Tab(text: isAr ? 'المستودعات والسحوبات 🏛️' : 'Hubs & Payouts 🏛️'),
                  Tab(text: isAr ? 'البضائع التالفة والعزل ⚠️' : 'Damaged & Quarantine ⚠️'),
                ],
              ),
            ),
          ),

          // ─── 4. Dynamic Tab View Body ─────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 580,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInboundTab(isAr),
                  _buildOutboundTab(isAr),
                  _buildKycApprovalsTab(isAr),
                  _buildHubsAndPayoutsTab(isAr),
                  _buildDamagedGoodsTab(isAr),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 1: Inbound Drop-offs Manager ────────────────────────────────────
  Widget _buildInboundTab(bool isAr) {
    final inbounds = _activities.where((a) => a.type == ActivityType.inbound).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isAr ? 'طلبات تفريغ ورصيد المستودعات' : 'Warehouse Inbound Receiving Queue',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminPanelColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${inbounds.length} ${isAr ? "طلبات" : "Requests"}',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (inbounds.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(isAr ? 'لا تتوفر طلبات تفريغ واردة حالياً' : 'No pending inbound drop-off requests.'),
            ),
          )
        else
          ...inbounds.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminPanelColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminPanelColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.move_to_inbox_rounded, color: AdminPanelColors.accentBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminPanelColors.textDark)),
                        const SizedBox(height: 2),
                        Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AdminPanelColors.textSub)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green.shade800,
                          content: Text(
                            isAr
                                ? 'تم تأكيد التفريغ وحفظ البضائع في الرصيف BAY-3 📦'
                                : 'Unloading confirmed & items marked in BAY-3 📦',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminPanelColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(isAr ? 'تأكيد التفريغ' : 'Approve Bay'),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── Tab 2: Outbound Orders Dispatch ──────────────────────────────────────
  Widget _buildOutboundTab(bool isAr) {
    final outbounds = _activities.where((a) => a.type == ActivityType.delivery).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr ? 'قائمة الشحنات الصادرة للسائقين' : 'Outbound Courier Dispatch Queue',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminPanelColors.textDark),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${outbounds.length} ${isAr ? "شحنات" : "Orders"}',
                style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (outbounds.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(isAr ? 'لا تتوفر طلبات شحن صادرة حالياً' : 'No pending outbound dispatch orders.'),
            ),
          )
        else
          ...outbounds.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminPanelColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminPanelColors.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: AdminPanelColors.accentGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminPanelColors.textDark)),
                        const SizedBox(height: 2),
                        Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AdminPanelColors.textSub)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green.shade800,
                          content: Text(
                            isAr
                                ? 'تم تسليم البولسية للسائق وجاري الشحن! 🚚'
                                : 'Waybill assigned to courier driver! 🚚',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminPanelColors.accentGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(isAr ? 'تسليم السائق' : 'Dispatch', style: const TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── Tab 3: KYC Approvals ────────────────────────────────────────────────
  Widget _buildKycApprovalsTab(bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr ? 'طلبات توثيق تراخيص التجار (KYC)' : 'Merchant Trade License Applications',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminPanelColors.textDark),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AdminPanelColors.textSub),
                  onPressed: _loadAdminData,
                  tooltip: isAr ? 'تحديث' : 'Refresh',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_pendingSellers.length} ${isAr ? "معلقة" : "Pending"}',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_pendingSellers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(isAr ? 'تمت الموافقة على جميع تراخيص التجار!' : 'All pending seller trade licenses approved!'),
            ),
          )
        else
          ...List.generate(_pendingSellers.length, (index) {
            final s = _pendingSellers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminPanelColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminPanelColors.accentWarning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AdminPanelColors.accentWarning, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['shop']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminPanelColors.textDark)),
                            Text('${s['owner']} • ${s['emirate']}', style: const TextStyle(fontSize: 12, color: AdminPanelColors.textSub)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _miniInfoRow(isAr ? 'رقم الرخصة التجاري' : 'Trade License No', s['license']!),
                  _miniInfoRow(isAr ? 'الرقم الضريبي TRN' : 'Tax TRN Number', s['trn']!),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveSeller(index, isAr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isAr ? 'اعتماد ونشر المتجر' : 'Approve & Activate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── Tab 4: Hubs Capacity & IBAN Payouts ─────────────────────────────────
  Widget _buildHubsAndPayoutsTab(bool isAr) {
    final hubs = [
      {'name': isAr ? 'مستودع دبي المركزي' : 'Dubai Central Hub', 'capacity': 0, 'shelves': '0 / 200 Shelves'},
      {'name': isAr ? 'مستودع أبوظبي KIZAD' : 'Abu Dhabi KIZAD Hub', 'capacity': 0, 'shelves': '0 / 150 Shelves'},
      {'name': isAr ? 'مستودع الشارقة الإقليمي' : 'Sharjah Regional Hub', 'capacity': 0, 'shelves': '0 / 100 Shelves'},
      {'name': isAr ? 'مركز العين اللوجستي' : 'Al Ain Logistics Hub', 'capacity': 0, 'shelves': '0 / 100 Shelves'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isAr ? 'سعة المستودعات وسحوبات الأرباح (14 يوماً)' : 'Fulfillment Hubs Occupancy & 14-Day Seller Holds',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminPanelColors.textDark),
        ),
        const SizedBox(height: 14),

        ...hubs.map((h) {
          final int cap = h['capacity'] as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminPanelColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(h['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(h['shelves'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminPanelColors.accentBlue)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: cap / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(cap > 80 ? Colors.orange : AdminPanelColors.primary),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Financial Payout Release Card
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PayoutSettlementPage()));
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AdminPanelColors.accentPurple.withValues(alpha: 0.3)),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: AdminPanelColors.accentPurple, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'تسوية أرصدة التجار المعلقة' : 'Seller IBAN Clearance Audit',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminPanelColors.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? 'يتم احتجاز 5% عمولة المنصة والإفراج عن 95% من صافي أرباح المبيعات لحسابات التجار البنكية بعد انقضاء 14 يوماً.'
                    : 'Holds 5% platform commission and clears 95% net sales balance to verified merchant UAE IBANs after 14-day hold.',
                style: const TextStyle(fontSize: 12, color: AdminPanelColors.textSub),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _adminStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminPanelColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(unit, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: AdminPanelColors.textSub)),
        ],
      ),
    );
  }

  Widget _miniInfoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 11, color: AdminPanelColors.textSub)),
            Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminPanelColors.textDark)),
          ],
        ),
      );

  // ─── Tab 5: Damaged Goods & Quarantine Manager ─────────────────────────────
  Widget _buildDamagedGoodsTab(bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Action Bar Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isAr ? 'منطقة الحجر وإدارة التلف بالمستودع' : 'Warehouse Quarantine Hold Area',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminPanelColors.textDark),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              icon: const Icon(Icons.add_alert_rounded, size: 15),
              label: Text(isAr ? 'تسجيل تلف جديد' : 'Log Damaged Unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _showLogDamageDialog(isAr),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_quarantineItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                isAr ? 'لا توجد بضائع تالفة أو محجوزة بالعزل حالياً.' : 'No damaged or quarantined items recorded.',
                style: const TextStyle(color: AdminPanelColors.textSub, fontSize: 13),
              ),
            ),
          )
        else
          ..._quarantineItems.map((item) => _buildQuarantineCard(
                isAr: isAr,
                sku: item['sku']?.toString() ?? 'SKU-001',
                productName: item['name']?.toString() ?? 'Item',
                hub: item['hub']?.toString() ?? 'Warehouse',
                damagedQty: (item['qty'] as num?)?.toInt() ?? 1,
                attribution: item['attribution']?.toString() ?? 'Inspection',
                compensation: item['compensation']?.toString() ?? 'AED 0.00',
                notes: item['notes']?.toString() ?? '',
              )),
      ],
    );
  }

  void _showLogDamageDialog(bool isAr) {
    final skuController = TextEditingController(text: 'SKU-DXB-002');
    final qtyController = TextEditingController(text: '2');
    final priceController = TextEditingController(text: '35.00');
    final notesController = TextEditingController(text: 'Unit dropped during forklift shelf relocation at Bay 3');
    String faultAttribution = 'warehouse_ops';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 10),
              Text(isAr ? 'تسجيل تلف ومصادرة عزل' : 'Log Damaged Item & Lock Quarantine', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: skuController,
                decoration: InputDecoration(labelText: isAr ? 'رمز الباركوود / SKU' : 'SKU / Barcode'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: isAr ? 'الكمية التالفة' : 'Damaged Qty'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: isAr ? 'سعر الوحدة (د.إ)' : 'Unit Price (AED)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(isAr ? 'الجهة المسؤولة عن التلف:' : 'Fault Attribution:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: faultAttribution,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'warehouse_ops', child: Text(isAr ? 'عمليات المستودع (تعويض التاجر 100%)' : 'NXN Hub Ops (Platform Pays Retail)')),
                  DropdownMenuItem(value: 'inbound_carrier', child: Text(isAr ? 'سائق الشحن الوارد (مرفوض بالبوابة)' : 'Inbound Carrier Driver (Rejected at Gate)')),
                  DropdownMenuItem(value: 'natural_expiry', child: Text(isAr ? 'انتهاء الصلاحية الطبيعي' : 'Natural Expiry / Merchant Product')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => faultAttribution = val);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: isAr ? 'تفاصيل التلف والتفتيش' : 'Defect Details & Inspection Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _marketplaceService.reportDamagedInventory(
                  sku: skuController.text,
                  hubCode: 'dxb',
                  damagedQuantity: int.tryParse(qtyController.text) ?? 1,
                  faultAttribution: faultAttribution,
                  unitPrice: double.tryParse(priceController.text) ?? 35.0,
                  notes: notesController.text,
                );
                setState(() {
                  _quarantineItems.add({
                    'sku': skuController.text,
                    'name': isAr ? 'صنف معزول' : 'Quarantined Unit',
                    'hub': 'DXB Hub (Bay 3)',
                    'qty': int.tryParse(qtyController.text) ?? 1,
                    'attribution': faultAttribution == 'warehouse_ops' ? 'NXN Hub Ops' : faultAttribution,
                    'compensation': 'AED ${res['compensation_amount']}',
                    'notes': notesController.text,
                  });
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green.shade800,
                      content: Text(
                        isAr
                            ? 'تم عزل العنصر بنجاح! التعويض: ${res['compensation_amount']} د.إ ⚠️'
                            : 'Item isolated to Quarantine! Wallet Compensation: AED ${res['compensation_amount']} ⚠️',
                      ),
                    ),
                  );
                }
              },
              child: Text(isAr ? 'تأكيد العزل والتعويض' : 'Lock Quarantine & Credit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarantineCard({
    required bool isAr,
    required String sku,
    required String productName,
    required String hub,
    required int damagedQty,
    required String attribution,
    required String compensation,
    required String notes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('$sku • $productName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                child: const Text('QUARANTINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF78350F))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniInfoRow(isAr ? 'الموقع الفعلي:' : 'Physical Location:', hub),
          _miniInfoRow(isAr ? 'الكمية التالفة:' : 'Damaged Qty:', '$damagedQty units'),
          _miniInfoRow(isAr ? 'الجهة المسؤولة:' : 'Fault Attribution:', attribution),
          _miniInfoRow(isAr ? 'تعويض المحفظة:' : 'Wallet Credit:', compensation),
          const SizedBox(height: 6),
          Text('Notes: $notes', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await _marketplaceService.resolveDamagedDisposition(
                      logId: 'LOG-1',
                      sku: sku,
                      dispositionAction: 'refurbished_liquidation',
                      refurbishedPrice: 20.0,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relisted as Refurbished in Marketplace! 🏷️')));
                    }
                  },
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.purple.shade300)),
                  child: Text(isAr ? '🏷️ إعادة إدراج كمفض' : '🏷️ Relist Refurbished', style: TextStyle(fontSize: 10, color: Colors.purple.shade800, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _marketplaceService.resolveDamagedDisposition(
                      logId: 'LOG-1',
                      sku: sku,
                      dispositionAction: 'database_write_off',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database Stock Write-off Completed! 🗑️')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  child: Text(isAr ? '🗑️ شطب من القاعدة' : '🗑️ Database Write-off', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
