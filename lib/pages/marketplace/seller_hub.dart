import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import 'public_product_detail_page.dart';
import '../smart_inventory_stage.dart';
import '../request_delivery_page.dart';
import '../create_shipment_page.dart';
import '../settings/notification_settings_page.dart';
import 'create_shop_page.dart';
import '../../l10n/app_localizations.dart';
import '../../models/marketplace_models.dart';
import 'seller_orders_page.dart';
import 'seller_products_page.dart';
import 'home_seller_marketplace_hub.dart';
import '../booking_page.dart';
import '../copilot_page.dart';
import '../notifications_page.dart';


/// The Store tab root. Automatically routes to:
///   - Guest  → [_GuestMarketplaceView]  (public catalog, no stats)
///   - Merchant/Operator → [_MerchantDashboardView] (full WMS dashboard)
class SellerHub extends StatelessWidget {
  const SellerHub({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MerchantDashboardView();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GUEST VIEW — Public marketplace catalog, zero operational data
// ══════════════════════════════════════════════════════════════════════════════

class _GuestMarketplaceView extends StatefulWidget {
  const _GuestMarketplaceView();

  @override
  State<_GuestMarketplaceView> createState() => _GuestMarketplaceViewState();
}

class _GuestMarketplaceViewState extends State<_GuestMarketplaceView> {
  final MarketplaceService _service = MarketplaceService();
  late Future<List<SmeProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    MarketplaceService.updateNotifier.addListener(_loadProducts);
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _service.getPublicMarketplaceProducts();
    });
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_loadProducts);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        slivers: [
          // ─── Header ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.bluePrimary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bluePrimary,
                ),
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'NXN Marketplace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16),
                        const SizedBox(width: 6),
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'تصفح التجار المعتمدين في الإمارات'
                              : 'Browse verified UAE merchants',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Sell on NXN banner ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _GuestSellBanner(),
          ),

          // ─── Product grid ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'المنتجات المميزة'
                        : 'Featured Products',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          AppColors.bluePrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'الكتالوج المباشر'
                          : 'Live catalog',
                      style: const TextStyle(
                          color: AppColors.bluePrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          FutureBuilder<List<SmeProduct>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return SliverToBoxAdapter(
                  child: _EmptyMarketplace(),
                );
              }

              final products = snapshot.data!;

              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyMarketplace(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductGridCard(
                        product: products[index]),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Compact "Sell on NXN" promotional card shown only to guests.
class _GuestSellBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final benefits = [
      (Icons.warehouse_rounded, isAr ? 'تخزين آمن في الإمارات' : 'Secure UAE Warehousing'),
      (Icons.local_shipping_rounded, isAr ? 'توصيل الميل الأخير' : 'Last-Mile Delivery'),
      (Icons.analytics_rounded, isAr ? 'مخزون حقيقي مباشر' : 'Real-time Inventory'),
      (Icons.verified_rounded, isAr ? 'تجار معتمدون رسمياً' : 'KYC-verified Sellers'),
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E6), Color(0xFFFFECC8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.storefront_rounded,
                    color: Colors.orange.shade800, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'ابدأ البيع على NXN' : 'Start Selling on NXN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? 'السوق اللوجستي الأول في الإمارات' : 'UAE\'s #1 logistics marketplace for SMEs',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Benefits grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 4.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: benefits.map((b) {
              return Row(
                children: [
                  Icon(b.$1,
                      color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b.$2,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateShopPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? 'إعداد المتجر الآن' : 'Setup Store Now',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMarketplace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isAr ? 'لا تتوفر منتجات حالياً.' : 'No products available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'عد مجدداً قريباً حيث يبدأ تجار NXN في نشر منتجاتهم.' : 'Check back soon as NXN merchants publish their catalogs.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final SmeProduct product;
  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProductDetailPage(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9DA8C4).withValues(alpha: 0.09),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: product.photoUrl != null
                    ? Image.network(
                        product.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.inventory_2_outlined,
                              size: 40, color: Colors.grey),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.inventory_2_outlined,
                            size: 40, color: Colors.grey),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? '${product.price.toStringAsFixed(2)} درهم' : 'AED ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.bluePrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.shopName ?? (isAr ? 'تاجر NXN' : 'NXN Merchant'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (product.isShopApproved)
                        const Icon(Icons.verified_rounded,
                            size: 13, color: Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MERCHANT VIEW — Full WMS dashboard with live stats, strict null-zeroing
// ══════════════════════════════════════════════════════════════════════════════

class _MerchantDashboardView extends StatefulWidget {
  const _MerchantDashboardView();

  @override
  State<_MerchantDashboardView> createState() =>
      _MerchantDashboardViewState();
}

class _MerchantDashboardViewState extends State<_MerchantDashboardView> {
  final MarketplaceService _service = MarketplaceService();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<MarketplaceShop?> _shopFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
    MarketplaceService.updateNotifier.addListener(_loadStats);
  }

  void _loadStats() {
    setState(() {
      _statsFuture = _service.getDashboardStats();
      _shopFuture = _service.getMyShop();
    });
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_loadStats);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: FutureBuilder(
        future: Future.wait([_statsFuture, _shopFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          MarketplaceShop? shop;
          final bool isLoading =
              snapshot.connectionState != ConnectionState.done;
          final bool hasLoaded = snapshot.hasData;

          // ── Strict zero-out: only populate stats when a real
          //    verified shop exists. Pending == no stats.
          final bool storeActive =
              hasLoaded && snapshot.data![1] != null;

          int activeShelves = 0;
          int totalItems = 0;
          int pendingOrders = 0;
          int shelvesThisMonth = 0;

          if (hasLoaded) {
            shop = snapshot.data![1] as MarketplaceShop?;
            final stats = snapshot.data![0] as Map<String, dynamic>;
            activeShelves = (stats['shelves'] as num?)?.toInt() ?? 0;
            totalItems = (stats['items'] as num?)?.toInt() ?? 0;
            pendingOrders = (stats['pendingOrders'] as num?)?.toInt() ?? 0;
            shelvesThisMonth = (stats['shelvesThisMonth'] as num?)?.toInt() ?? 0;
          }

          // Capacity — safe, can never leak mock values
          final double capacityPercentage = (activeShelves > 0 && storeActive)
              ? (totalItems / (activeShelves * 50.0)).clamp(0.0, 1.0)
              : 0.0;

          // Pending-state flag drives locked UI below setup card
          final bool storeSetupPending =
              hasLoaded && (shop == null || !shop.isApproved);

          return CustomScrollView(
            slivers: [
              // ─── Header ────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 125,
                pinned: true,
                backgroundColor: AppColors.bluePrimary,
                automaticallyImplyLeading: false,
                title: Text(
                  isAr ? 'لوحة تحكم المتجر' : 'Store Dashboard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, _) {
                      final isAr = localeProvider.locale.languageCode == 'ar';
                      return InkWell(
                        onTap: () => localeProvider.toggleLocale(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, color: Colors.white, size: 14),
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
                  const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 22),
                      tooltip: isAr ? 'المساعد الذكي Copilot' : 'Logistics Copilot AI',
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CopilotPage())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 24),
                      tooltip: isAr ? 'الإشعارات' : 'Notifications',
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const NotificationsPage())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const NotificationSettingsPage())),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

              // ─── Setup Pending Banner (if applicable) ──────────────
              if (!isLoading && storeSetupPending)
                SliverToBoxAdapter(
                  child: _SetupPendingCard(
                    onSetupComplete: _loadStats,
                  ),
                ),

              // ─── Live Stats & Operations Section ────────────────────
              SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Capacity bar
                        _CapacityCard(
                          capacityPercentage: capacityPercentage,
                          activeShelves: activeShelves,
                          totalItems: totalItems,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Stat cards row
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: l10n.shelvesStat,
                                value: isLoading
                                    ? '–'
                                    : '$activeShelves',
                                icon: Icons.shelves,
                                color: Colors.orange,
                                trend: l10n.trendPlusMonth(
                                    shelvesThisMonth),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: l10n.itemsStat,
                                value: isLoading
                                    ? '–'
                                    : '$totalItems',
                                icon: Icons.inventory_2,
                                color: AppColors.bluePrimary,
                                trend: l10n.trendStocked(
                                  activeShelves > 0
                                      ? ((totalItems /
                                                  (activeShelves *
                                                      50)) *
                                              100)
                                          .clamp(0, 100)
                                          .toInt()
                                      : 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const RequestDeliveryPage())),
                          borderRadius: BorderRadius.circular(24),
                          child: _StatCard(
                            title: l10n.pendingOrdersStat,
                            value: isLoading ? '–' : '$pendingOrders',
                            icon: Icons.local_shipping,
                            color: Colors.redAccent,
                            isFullWidth: true,
                            trend: pendingOrders > 0
                                ? l10n.actionRequired
                                : (Localizations.localeOf(context).languageCode == 'ar' ? 'مكتمل' : 'All Caught Up'),
                            trendColor: pendingOrders > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Operations grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'إدارة العمليات والتنفيذ' : 'Operations Management',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isAr ? 'سير العمل' : 'Live Workflow',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.bluePrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.02,
                          children: [
                            _ActionCard(
                              title: isAr ? 'حجز مساحات ورفوف' : 'Rent Shelves',
                              subtitle: isAr ? 'استئجار رفوف قياسية بـ 100 درهم شهرياً' : 'Book standard warehouse shelves at 100 AED/mo',
                              badge: isAr ? '100 درهم' : '100 AED',
                              icon: Icons.view_in_ar_rounded,
                              color: const Color(0xFF003C8E),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const BookingPage())),
                            ),
                            _ActionCard(
                              title: isAr ? 'مساعد الذكاء الاصطناعي' : 'Logistics Copilot AI',
                              subtitle: isAr ? 'استعلام المخزون والعمليات عبر الذكاء الاصطناعي' : 'Ask questions about stock, shelves & orders',
                              badge: 'AI',
                              icon: Icons.auto_awesome_rounded,
                              color: const Color(0xFF6C5CE7),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CopilotPage())),
                            ),
                            _ActionCard(
                              title: isAr ? 'مخزوني ومواقع الأرفف' : 'My Inventory',
                              subtitle: isAr ? 'متابعة الأصناف والكميات وحالة التخزين' : 'Live stock audit, shelf positions & SKU breakdown',
                              badge: '$totalItems ${isAr ? "صنف" : "Units"}',
                              icon: Icons.inventory_2_rounded,
                              color: const Color(0xFF2E86DE),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SmartInventoryStageEN())),
                            ),
                            _ActionCard(
                              title: isAr ? 'كتالوج المنتجات والأسعار' : 'Product Catalog & Pricing',
                              subtitle: isAr ? 'إدارة القائمة وتحديث الأسعار وإضافة منتجات' : 'Manage marketplace listings, prices & add new SKUs',
                              badge: isAr ? 'الكتالوج' : 'Catalog',
                              icon: Icons.add_business_rounded,
                              color: const Color(0xFF10AC84),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SellerProductsPage()));
                                _loadStats();
                              },
                            ),
                            _ActionCard(
                              title: isAr ? 'حجز موعد توريد البضائع' : 'Book Cargo Drop-off',
                              subtitle: isAr ? 'حجز موعد تسليم البضائع بمكتب الاستقبال وإصدار رمز ASN' : 'Schedule cargo drop-off at reception desk with ASN QR',
                              badge: isAr ? 'التوريد' : 'Inbound',
                              icon: Icons.move_to_inbox_rounded,
                              color: const Color(0xFFFF9F43),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateShipmentPage(initialIsDropOff: true),
                                ),
                              ),
                            ),
                            _ActionCard(
                              title: isAr ? 'الطلبات الواردة' : 'Incoming Orders',
                              subtitle: isAr ? 'تتبع وإدارة طلبات المشترين ومراحل التجهيز' : 'Track buyer orders, update status & manage fulfillment',
                              badge: isAr ? 'الطلبات' : 'Orders',
                              icon: Icons.receipt_long_rounded,
                              color: const Color(0xFF9B59B6),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SellerOrdersPage()),
                              ),
                            ),
                            _ActionCard(
                              title: isAr ? 'طلب شحن وتوصيل' : 'Request Delivery',
                              subtitle: isAr ? 'تنفيذ طلبات العملاء وحجز شركات الشحن' : 'Dispatch customer orders & book courier pickup',
                              badge: isAr ? 'التسليم' : 'Outbound',
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFF8B5CF6),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RequestDeliveryPage(),
                                ),
                              ),
                            ),
                            _ActionCard(
                              title: isAr ? 'منصة الأسر والشركات الصغيرة' : 'Home Seller Sales Hub',
                              subtitle: isAr ? 'أرفف قياسية بـ 100 درهم وبوابة دفع Fintx المعتمدة' : '100 AED standard shelves, Fintx gateway & transparent pricing',
                              badge: isAr ? 'قناة جديدة' : 'New Channel',
                              icon: Icons.storefront_rounded,
                              color: const Color(0xFF1E3A8A),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const HomeSellerMarketplaceHubPage()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Visual High-Tech Capacity Card ──────────────────────────────────────────

class _CapacityCard extends StatelessWidget {
  final double capacityPercentage;
  final int activeShelves;
  final int totalItems;
  final bool isLoading;

  const _CapacityCard({
    required this.capacityPercentage,
    required this.activeShelves,
    required this.totalItems,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final int pctInt = (capacityPercentage * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.pie_chart_outline_rounded, color: Colors.cyanAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'سعة أرفف التخزين بالمستودع' : 'Warehouse Shelf Capacity',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr ? 'مراقبة الرصيد التخزيني المباشر' : 'Live Warehouse Stock Audit',
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: capacityPercentage > 0.85
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: capacityPercentage > 0.85 ? Colors.redAccent : Colors.cyanAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '$pctInt% ${isAr ? "مستخدم" : "Used"}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: capacityPercentage > 0.85 ? Colors.redAccent : Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: capacityPercentage.clamp(0.02, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: capacityPercentage > 0.85
                          ? [Colors.orange, Colors.redAccent]
                          : [Colors.cyan, AppColors.bluePrimary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: capacityPercentage > 0.85
                            ? Colors.redAccent.withValues(alpha: 0.6)
                            : Colors.cyan.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _capacityChip(
                isAr ? '$totalItems قطعة مخزنة' : '$totalItems Items Stored',
                Icons.inventory_2_rounded,
                Colors.cyanAccent,
              ),
              const SizedBox(width: 8),
              _capacityChip(
                isAr ? '$activeShelves أرفف نشطة' : '$activeShelves Active Shelves',
                Icons.grid_view_rounded,
                Colors.amberAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _capacityChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Setup Pending Card ───────────────────────────────────────────────────────

class _SetupPendingCard extends StatelessWidget {
  final VoidCallback onSetupComplete;
  const _SetupPendingCard({required this.onSetupComplete});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration:
                    const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.storefront_rounded,
                    color: Colors.orange.shade800, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'سجّل متجرك الآن' : 'Register Your Store',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? 'قم بإنشاء ملفك التجاري للبيع على سوق NXN.' : 'Setup your profile to sell on NXN Marketplace.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateShopPage()),
                );
                if (result == true) onSetupComplete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? 'إعداد المتجر الآن' : 'Setup Store Now',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable stat / action card widgets ─────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;
  final String? trend;
  final Color? trendColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (isFullWidth && trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (trendColor ?? Colors.green)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: trendColor ?? Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isFullWidth && trend != null) ...[
            const SizedBox(height: 12),
            Text(
              trend!,
              style: TextStyle(
                fontSize: 12,
                color: trendColor ?? Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badge != null && badge!.isNotEmpty) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(
                        isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
