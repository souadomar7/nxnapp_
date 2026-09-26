import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/locale_provider.dart';
import '../data/inventory_controller.dart';
import '../data/receive_result.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'receive_goods_stage.dart';
import 'marketplace/add_product_page.dart';
import '../models/marketplace_models.dart';
import '../services/marketplace_service.dart';

class InventoryColors {
  static const primary = AppColors.bluePrimary;
  static const background = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textSub = Color(0xFF64748B);
  static const cardBorder = Color(0xFFE2E8F0);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
  static const accentWarning = Color(0xFFF59E0B);
  static const accentDanger = Color(0xFFEF4444);
}

class SmartInventoryStageEN extends StatefulWidget {
  final ReceiveResult? result;

  const SmartInventoryStageEN({super.key, this.result});

  @override
  State<SmartInventoryStageEN> createState() => _SmartInventoryStageENState();
}

class _SmartInventoryStageENState extends State<SmartInventoryStageEN> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryController>().load();
    });
    MarketplaceService.updateNotifier.addListener(_refreshState);
  }

  void _refreshState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MarketplaceService.updateNotifier.removeListener(_refreshState);
    super.dispose();
  }

  String _fmtDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InventoryController>();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: InventoryColors.background,
      body: RefreshIndicator(
        onRefresh: () => context.read<InventoryController>().load(),
        color: InventoryColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── 1. Modern Hero Sliver Header ─────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: InventoryColors.primary,
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
                      colors: [AppColors.bluePrimary, AppColors.blueMid],
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
                                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAr ? 'المخزون الذكي' : 'Smart Inventory',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAr ? 'متابعة حية للمستودع وتحليلات المخزون' : 'Live warehouse tracking & stock analytics',
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
                                  color: Colors.greenAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAr ? 'مباشر ⚡' : 'Live ⚡',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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

            // ─── 2. Main Content Body ────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: InventoryColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inbound summary from receiving flow (Stage 5)
                    if (widget.result != null) ...[
                      _buildInboundSummaryCard(isAr),
                      const SizedBox(height: 24),
                    ],

                    // Metrics Overview (4 Cards Grid)
                    _buildSectionTitle(
                      isAr ? 'نظرة عامة على المخزون' : 'Stock Metrics Overview',
                      subtitle: isAr ? 'ملخص الكميات وحالة الأرفف والشرائح' : 'Real-time overview of shelves and stock values',
                    ),
                    const SizedBox(height: 14),

                    if (c.loading)
                      const _SkeletonStats()
                    else
                      _buildMetricsGrid(context, c, isAr),

                    const SizedBox(height: 24),

                    // Visual Analytics Bar Chart Card
                    _buildSectionTitle(
                      isAr ? 'توزيع المخزون' : 'Inventory Distribution',
                      subtitle: isAr ? 'الكميات حسب فئات التخزين والرفوف' : 'Stock distribution across warehouse categories',
                    ),
                    const SizedBox(height: 14),
                    _buildAnalyticsChartCard(context, c, isAr),

                    const SizedBox(height: 24),

                    // Active Rentals / Warehouse Capacity Carousel
                    if (c.summary.activeRentals.isNotEmpty) ...[
                      _buildSectionTitle(
                        isAr ? 'المستودعات والأرفف النشطة' : 'Active Warehouse Shelves',
                        subtitle: isAr ? 'الفروع المستأجرة وسعة التخزين الحالية' : 'Rented spaces across UAE fulfillment hubs',
                      ),
                      const SizedBox(height: 14),
                      _buildActiveRentalsCarousel(c, isAr),
                      const SizedBox(height: 24),
                    ],

                    // Operations Suite Actions
                    _buildSectionTitle(
                      isAr ? 'إجراءات السريعة' : 'Quick Operations Suite',
                      subtitle: isAr ? 'إدارة التزويد والكتالوج والتقارير' : 'Restock, list products, or export PDF reports',
                    ),
                    const SizedBox(height: 14),
                    _buildOperationsSuite(context, c, isAr),

                    const SizedBox(height: 28),

                    // Stock SKU Breakdown List
                    _buildSectionTitle(
                      isAr ? 'جدول منتجات المخزون (SKU)' : 'Inventory SKU Breakdown',
                      subtitle: isAr ? 'قائمة المنتجات وحالة توفر الكميات' : 'Detailed catalog list with stock level badges',
                    ),
                    const SizedBox(height: 14),
                    _buildSkuBreakdownSection(c, isAr),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Title Builder ───────────────────────────────────────────────
  Widget _buildSectionTitle(String title, {required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: InventoryColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: InventoryColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: InventoryColors.textSub,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Inbound Summary Card (Stage 5) ──────────────────────────────────────
  Widget _buildInboundSummaryCard(bool isAr) {
    final res = widget.result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InventoryColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: InventoryColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                decoration: BoxDecoration(
                  color: InventoryColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.move_to_inbox_rounded, color: InventoryColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'شحنة الوارد الأخيرة' : 'Last Inbound Receiving',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: InventoryColors.textDark),
                    ),
                    Text(
                      _fmtDateTime(res.scheduledAt),
                      style: const TextStyle(fontSize: 11, color: InventoryColors.textSub),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  isAr ? 'مستلمة' : 'Received',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _infoRow(isAr ? 'رقم التخزين' : 'Storage No.', res.storageNo, isHighlight: true),
          _infoRow(isAr ? 'رقم الرصيف / المنصة' : 'Bay Location', res.bay),
          _infoRow(isAr ? 'فئة درجة الحرارة' : 'Storage Mode', res.storageMode),
          _infoRow(isAr ? 'العمال المخصصون' : 'Assigned Workers', '${res.workers} (AED ${res.workers * 50})'),
        ],
      ),
    );
  }

  // ─── Metrics 4-Grid ──────────────────────────────────────────────────────
  Widget _buildMetricsGrid(BuildContext context, InventoryController c, bool isAr) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: isAr ? 'الأرفف النشطة' : 'Active Shelves',
                value: '${c.summary.suppliers}',
                unit: isAr ? 'أرفف' : 'Shelves',
                icon: Icons.shelves,
                color: InventoryColors.accentBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                title: isAr ? 'إجمالي المخزون' : 'Stock Value',
                value: '${(c.summary.totalValue / 1000).toStringAsFixed(1)}k',
                unit: isAr ? 'درهم' : 'AED',
                icon: Icons.monetization_on_rounded,
                color: InventoryColors.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: isAr ? 'مخزون منخفض' : 'Low Stock Alert',
                value: '${c.summary.lowStock}',
                unit: isAr ? 'قطع' : 'SKUs',
                icon: Icons.warning_amber_rounded,
                color: InventoryColors.accentWarning,
                isWarning: c.summary.lowStock > 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                title: isAr ? 'منتهي المخزون' : 'Out of Stock',
                value: '${c.summary.outOfStock}',
                unit: isAr ? 'قطع' : 'SKUs',
                icon: Icons.highlight_off_rounded,
                color: InventoryColors.accentDanger,
                isWarning: c.summary.outOfStock > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Analytics Chart Card ────────────────────────────────────────────────
  Widget _buildAnalyticsChartCard(BuildContext context, InventoryController c, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: InventoryColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
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
              Text(
                isAr ? 'تحليل السعة والتوزيع' : 'Capacity & Stock Chart',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: InventoryColors.textDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: InventoryColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAr ? 'تحديث تلقائي' : 'Real-time Sync',
                  style: const TextStyle(fontSize: 11, color: InventoryColors.textSub, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: c.series.isEmpty
                ? Center(
                    child: Text(
                      isAr ? 'لا تتوفر بيانات رسم بياني حالياً' : AppLocalizations.of(context)!.noChartData,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : _SimpleBars(
                    values: c.series.map((e) => e.value.toDouble()).toList(),
                    labels: c.series.map((e) => e.label).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Active Rentals Carousel ─────────────────────────────────────────────
  Widget _buildActiveRentalsCarousel(InventoryController c, bool isAr) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: c.summary.activeRentals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final r = c.summary.activeRentals[index];
          final String rawWh = r['warehouse'] ?? 'Unknown Hub';
          String branchName = rawWh;
          if (rawWh == 'aln') branchName = isAr ? 'مستودع العين المركزي' : 'Al Ain Central Warehouse';
          if (rawWh == 'dxb') branchName = isAr ? 'مستودع دبي المركزي' : 'Dubai Central Warehouse';
          if (rawWh == 'auh') branchName = isAr ? 'مستودع أبوظبي المركزي' : 'Abu Dhabi Central Warehouse';
          if (rawWh == 'shj') branchName = isAr ? 'مستودع الشارقة المركزي' : 'Sharjah Central Warehouse';

          final int shelves = r['shelves'] ?? 1;

          return Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: InventoryColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(isAr ? 'نشط' : 'Active', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Text(
                      '$shelves ${isAr ? "أرفف" : "Shelves"}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InventoryColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  branchName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: InventoryColors.textDark),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Operations Suite ────────────────────────────────────────────────────
  Widget _buildOperationsSuite(BuildContext context, InventoryController c, bool isAr) {
    return Column(
      children: [
        _ActionTile(
          label: isAr ? 'إعادة تعبئة وتسليم البضائع' : AppLocalizations.of(context)!.restockBtn,
          subtitle: isAr ? 'جدولة حجز رصيد التسليم والعمال' : 'Schedule warehouse drop-off & worker assignment',
          icon: Icons.move_to_inbox_rounded,
          color: InventoryColors.accentBlue,
          onTap: c.loading
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReceiveGoodsStagePageEN()),
                  );
                  if (context.mounted) {
                    context.read<InventoryController>().load();
                  }
                },
        ),
        const SizedBox(height: 10),
        _ActionTile(
          label: isAr ? 'إضافة منتج جديد للكتالوج' : 'Add New Product to Catalog',
          subtitle: isAr ? 'إدراج صنف جديد وسعره في السوق' : 'List a new item SKU with price & photo',
          icon: Icons.add_business_rounded,
          color: InventoryColors.accentGreen,
          onTap: c.loading
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddProductPage()),
                  );
                  if (context.mounted) {
                    context.read<InventoryController>().load();
                  }
                },
        ),
        const SizedBox(height: 10),
        _ActionTile(
          label: isAr ? 'تحميل تقارير وسجلات المخزون' : AppLocalizations.of(context)!.viewReportsBtn,
          subtitle: isAr ? 'تصدير كشف حركة الأصناف وتدقيق المخزون' : 'Export PDF stock audit and history report',
          icon: Icons.assessment_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: c.loading
              ? null
              : () async {
                  final url = await c.openReports();
                  if (context.mounted) {
                    _toast(
                      context,
                      url != null
                          ? (isAr ? 'جاري فتح تقرير المخزون...' : AppLocalizations.of(context)!.openingReports)
                          : (isAr ? 'لا تتوفر تقارير حالياً.' : AppLocalizations.of(context)!.noReportsAvailable),
                    );
                  }
                },
        ),
      ],
    );
  }

  // ─── SKU Breakdown Section ───────────────────────────────────────────────
  Widget _buildSkuBreakdownSection(InventoryController c, bool isAr) {
    return FutureBuilder<List<SmeInventory>>(
      future: MarketplaceService().getInventory(),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> itemsList = [];

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          for (var item in snapshot.data!) {
            String statusKey = item.status;
            if (item.status != 'quarantine') {
              if (item.quantity > 0 && item.quantity < 10) {
                statusKey = 'low_stock';
              } else if (item.quantity <= 0) {
                statusKey = 'out_of_stock';
              } else {
                statusKey = 'in_stock';
              }
            }

            String name = item.productName ?? (isAr ? 'منتج مخزون' : 'Inventory Product');
            if (isAr) {
              if (name.contains('Inbound Batch')) {
                name = name.replaceAll('Inbound Batch', 'دفعة شحنة واردة');
              } else if (name.contains('Premium Espresso Beans')) {
                name = 'حبوب إسبريسو فاخرة';
              } else if (name.contains('Wireless Earbuds Pro')) {
                name = 'سماعات لاسلكية برو';
              }
            }

            String hub = item.warehouseName ?? (isAr ? 'مستودع دبي المركزي' : 'Dubai Central Hub');
            if (isAr) {
              if (hub.contains('Dubai Central') || hub.contains('dxb')) {
                hub = 'مستودع دبي المركزي';
              } else if (hub.contains('Abu Dhabi') || hub.contains('auh')) {
                hub = 'مستودع أبوظبي المركزي';
              } else if (hub.contains('Sharjah') || hub.contains('shj')) {
                hub = 'مستودع الشارقة المركزي';
              } else if (hub.contains('Al Ain') || hub.contains('aln')) {
                hub = 'مستودع العين المركزي';
              }
            }

            itemsList.add({
              'name': name,
              'sku': item.sku ?? item.id,
              'qty': item.quantity,
              'status': statusKey,
              'category': hub,
            });
          }
        } else {
          itemsList.addAll([
            {'name': isAr ? 'طقم أكواب سيراميك' : 'Ceramic Mug Set', 'sku': 'SKU-MUG-001', 'qty': 42, 'status': 'in_stock', 'category': isAr ? 'أدوات منزلية' : 'Homeware'},
            {'name': isAr ? 'زيت زيتون عضوي 1 لتر' : 'Organic Olive Oil 1L', 'sku': 'SKU-OIL-992', 'qty': 8, 'status': 'low_stock', 'category': isAr ? 'أغذية معلبة' : 'FMCG Food'},
            {'name': isAr ? 'حليب اللوز (12×1 لتر)' : 'Almond Milk Pack (12x1L)', 'sku': 'SKU-MLK-304', 'qty': 115, 'status': 'in_stock', 'category': isAr ? 'مشروبات' : 'Beverages'},
            {'name': isAr ? 'سماعات لاسلكية برو' : 'Wireless Pro Earbuds', 'sku': 'SKU-AUD-441', 'qty': 0, 'status': 'out_of_stock', 'category': isAr ? 'إلكترونيات' : 'Electronics'},
            {'name': isAr ? 'عسل طبيعي 500غ' : 'Natural Honey Jar 500g', 'sku': 'SKU-HNY-110', 'qty': 4, 'status': 'low_stock', 'category': isAr ? 'أغذية معلبة' : 'FMCG Food'},
          ]);
        }

        final filtered = itemsList.where((s) {
          final nameMatches = (s['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (s['sku'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
          if (_selectedFilter == 'all') return nameMatches;
          return nameMatches && s['status'] == _selectedFilter;
        }).toList();

        return Column(
          children: [
            // Search input
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: isAr ? 'ابحث عن اسم المنتج أو رمز SKU...' : 'Search product name or SKU code...',
                prefixIcon: const Icon(Icons.search_rounded, color: InventoryColors.textSub),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: InventoryColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: InventoryColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', isAr ? 'الكل' : 'All SKUs', isAr),
                  const SizedBox(width: 8),
                  _filterChip('in_stock', isAr ? 'متوفر' : 'In Stock', isAr),
                  const SizedBox(width: 8),
                  _filterChip('low_stock', isAr ? 'منخفض' : 'Low Stock', isAr),
                  const SizedBox(width: 8),
                  _filterChip('out_of_stock', isAr ? 'منتهي' : 'Out of Stock', isAr),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Items list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final int qty = item['qty'] as int;
                final String status = item['status'] as String;

                Color statusColor = Colors.green;
                String statusText = isAr ? 'متوفر' : 'In Stock';
                if (status == 'low_stock') {
                  statusColor = Colors.orange;
                  statusText = isAr ? 'مخزون منخفض' : 'Low Stock';
                } else if (status == 'out_of_stock') {
                  statusColor = Colors.red;
                  statusText = isAr ? 'نفذ المخزون' : 'Out of Stock';
                } else if (status == 'quarantine') {
                  statusColor = Colors.amber.shade900;
                  statusText = isAr ? 'تحت العزل' : 'Quarantine';
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: InventoryColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: InventoryColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: statusColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: InventoryColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['sku']} • ${item['category']}',
                              style: const TextStyle(fontSize: 11, color: InventoryColors.textSub),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$qty ${isAr ? "قطعة" : "Units"}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: statusColor),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String key, String label, bool isAr) {
    final selected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: InventoryColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : InventoryColors.textDark,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _infoRow(String k, String v, {bool isHighlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                k,
                style: const TextStyle(color: InventoryColors.textSub, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isHighlight ? InventoryColors.primary : InventoryColors.textDark,
                  fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                  fontSize: isHighlight ? 15 : 13,
                ),
              ),
            ),
          ],
        ),
      );

  static void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─── Metric Card Component ─────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isWarning;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isWarning ? color.withValues(alpha: 0.5) : InventoryColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                unit,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: InventoryColors.textSub, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Action Tile Component ─────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: InventoryColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: InventoryColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: InventoryColors.textSub),
                  ),
                ],
              ),
            ),
            Icon(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? Icons.arrow_back_ios_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Simple Bars Chart Component ───────────────────────────────────────────
class _SimpleBars extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _SimpleBars({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox();

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final topY = maxVal == 0 ? 10.0 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${labels[group.x.toInt()]}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: rod.toY.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.yellowAccent),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(values.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: InventoryColors.primary,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: topY,
                  color: const Color(0xFFF1F5F9),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Skeleton Stats Component ──────────────────────────────────────────────
class _SkeletonStats extends StatelessWidget {
  const _SkeletonStats();

  @override
  Widget build(BuildContext context) {
    Widget skel() => Expanded(
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: InventoryColors.cardBorder),
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            skel(),
            const SizedBox(width: 12),
            skel(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            skel(),
            const SizedBox(width: 12),
            skel(),
          ],
        ),
      ],
    );
  }
}
