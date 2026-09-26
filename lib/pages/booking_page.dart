import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'checkout_page.dart';
import '../models/invoice.dart';
import '../services/marketplace_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/brand_logo.dart';
import '../theme.dart';

// ==============================================================================
// 1. DATA MODELS & LOGIC (unchanged)
// ==============================================================================

class PrimeWarehouse {
  final String id;
  final String nameEn;
  final String nameAr;
  final String subtitleEn;
  final String subtitleAr;
  final int totalShelves;
  final List<String> storageTags;
  final IconData icon;

  const PrimeWarehouse({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.totalShelves,
    required this.storageTags,
    required this.icon,
  });
}

class PriceBreakdown {
  final double subtotal;
  final double platformFee;
  final double vat;
  final double total;

  PriceBreakdown({
    required this.subtotal,
    required this.platformFee,
    required this.vat,
    required this.total,
  });
}

class BookingConfig {
  bool isSelected;
  int shelves;
  int durationMonths;
  bool addWorkers;
  int workerCount;

  BookingConfig({
    this.isSelected = false,
    this.shelves = 5,
    this.durationMonths = 1,
    this.addWorkers = false,
    this.workerCount = 1,
  });

  /// Calculate price breakdown using configurable platform rates.
  /// Defaults mirror the legacy hardcoded values so existing call-sites
  /// continue to work without changes. Pass values from
  /// PlatformSettingsProvider for live server-driven pricing.
  PriceBreakdown calculateBreakdown({
    double shelfBasePriceAed = 100.0,
    double workerFeePerUnit = 50.0,
    double platformFeeRate = 0.05,
    double vatRate = 0.05,
  }) {
    final double baseCost = shelfBasePriceAed * shelves * durationMonths;
    final double workerFee = addWorkers ? (workerFeePerUnit * workerCount) : 0.0;
    final double subtotal = baseCost + workerFee;
    final double platformFee = subtotal * platformFeeRate;
    final double vat = (subtotal + platformFee) * vatRate;
    final double total = subtotal + platformFee + vat;

    return PriceBreakdown(
        subtotal: subtotal, platformFee: platformFee, vat: vat, total: total);
  }
}

// ==============================================================================
// 2. MAIN PAGE
// ==============================================================================

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final List<PrimeWarehouse> _warehouses = [
    const PrimeWarehouse(
      id: 'dxb',
      nameEn: 'Dubai',
      nameAr: 'دبي',
      subtitleEn: 'Al Quoz Logistics Hub',
      subtitleAr: 'منطقة القوز اللوجستية',
      totalShelves: 200,
      storageTags: ['Fast Dispatch', '24/7 Access', 'Secured'],
      icon: Icons.business_outlined,
    ),
    const PrimeWarehouse(
      id: 'auh',
      nameEn: 'Abu Dhabi',
      nameAr: 'أبو ظبي',
      subtitleEn: 'KIZAD Industrial Zone',
      subtitleAr: 'مدينة كيزاد الصناعية',
      totalShelves: 150,
      storageTags: ['Standard Bay', 'Forklift Ready', 'Secured'],
      icon: Icons.location_city_outlined,
    ),
    const PrimeWarehouse(
      id: 'shj',
      nameEn: 'Sharjah',
      nameAr: 'الشارقة',
      subtitleEn: 'Industrial Area 4',
      subtitleAr: 'المنطقة الصناعية 4',
      totalShelves: 100,
      storageTags: ['Fast Dispatch', 'Central Location'],
      icon: Icons.mosque_outlined,
    ),
    const PrimeWarehouse(
      id: 'aln',
      nameEn: 'Al Ain',
      nameAr: 'العين',
      subtitleEn: 'Sanaiya Logistics Oasis',
      subtitleAr: 'صناعية العين',
      totalShelves: 100,
      storageTags: ['Regional Hub', 'High Capacity'],
      icon: Icons.landscape_outlined,
    ),
  ];

  final Map<String, BookingConfig> _configs = {};

  double get _grandTotal => _configs.values
      .where((c) => c.isSelected)
      .fold<double>(0.0, (sum, c) => sum + c.calculateBreakdown().total);

  int get _selectedCount => _configs.values.where((c) => c.isSelected).length;

  @override
  void initState() {
    super.initState();
    for (var w in _warehouses) {
      _configs[w.id] = BookingConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final currencyFormat =
        NumberFormat.currency(symbol: 'AED ', decimalDigits: 0);
    final bottomPadding = _selectedCount > 0 ? 100.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _BookingHeader(l10n: l10n, isAr: isAr),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: l10n.step1Title),
                      const SizedBox(height: 0),
                      _WarehouseGrid(
                        warehouses: _warehouses,
                        configs: _configs,
                        isAr: isAr,
                        onToggle: (id) => setState(() {
                          _configs[id]!.isSelected = !_configs[id]!.isSelected;
                        }),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedCount > 0) ...[
                        _SectionTitle(title: l10n.step2CustomizeSpace),
                        const SizedBox(height: 8),
                        StreamBuilder<Map<String, int>>(
                          stream:
                              MarketplaceService().getAvailableShelvesStream(),
                          builder: (context, snapshot) {
                            final availableMap = snapshot.data ?? {};
                            return Column(
                              children: _warehouses
                                  .where((w) => _configs[w.id]!.isSelected)
                                  .map((w) {
                                final int available = availableMap[w.id] ?? 50;
                                return _RentalConfigCard(
                                  warehouse: w,
                                  config: _configs[w.id]!,
                                  isAr: isAr,
                                  availableShelves: available,
                                  onUpdate: () => setState(() {}),
                                  onRemove: () => setState(
                                      () => _configs[w.id]!.isSelected = false),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ] else
                        _VisualWarehouseShowcase(
                          warehouses: _warehouses,
                          isAr: isAr,
                          onSelectWarehouse: (id) => setState(() {
                            _configs[id]!.isSelected = true;
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedCount > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomQuoteBar(
                l10n: l10n,
                grandTotal: _grandTotal,
                currencyFormat: currencyFormat,
                onBook: () => _showQuoteDialog(context, currencyFormat, isAr),
              ),
            ),
        ],
      ),
    );
  }

  void _showQuoteDialog(BuildContext context, NumberFormat fmt, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => _QuoteDialog(
        warehouses:
            _warehouses.where((w) => _configs[w.id]!.isSelected).toList(),
        configs: _configs,
        currencyFormat: fmt,
        isAr: isAr,
        grandTotal: _grandTotal,
      ),
    );
  }
}

// ==============================================================================
// 3. SUB-WIDGETS
// ==============================================================================

class _BookingHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isAr;

  const _BookingHeader({required this.l10n, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF003C8E),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF06152D),
                Color(0xFF003C8E),
                Color(0xFF1E50FF),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Ambient glow circles
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const BrandLogo(height: 28, isLight: true),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded,
                                    color: Color(0xFF38BDF8), size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  isAr ? 'حجز فوري معتمد' : 'Instant Hold & Pass',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'اختر مستودعك اللوجستي' : 'Choose Your Warehouse Hub',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'مستودعات ذكية متكاملة ومؤمنة في كافة إمارات الدولة'
                                : 'Prime smart & secured warehousing across UAE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Feature highlights row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _HeaderBadge(
                                  icon: Icons.timer_outlined,
                                  label: isAr ? 'ضمان حجز 10 دقائق' : '10-Min Lock Guarantee',
                                ),
                                const SizedBox(width: 6),
                                _HeaderBadge(
                                  icon: Icons.verified_user_outlined,
                                  label: isAr ? 'مستودع آمن ومؤمن' : 'Secured & Insured',
                                ),
                                const SizedBox(width: 6),
                                _HeaderBadge(
                                  icon: Icons.qr_code_2_rounded,
                                  label: isAr ? 'تصريح دخول فوري' : 'QR Gate Pass',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ──────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.bluePrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.bluePrimary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Warehouse Grid ─────────────────────────────────────────────────────────────
class _WarehouseGrid extends StatelessWidget {
  final List<PrimeWarehouse> warehouses;
  final Map<String, BookingConfig> configs;
  final bool isAr;
  final Function(String) onToggle;

  const _WarehouseGrid({
    required this.warehouses,
    required this.configs,
    required this.isAr,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (warehouses.isEmpty) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.15,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: warehouses.map((w) {
        final isSelected = configs[w.id]!.isSelected;
        return _GridItem(
          w: w,
          isSelected: isSelected,
          isAr: isAr,
          onTap: () => onToggle(w.id),
        );
      }).toList(),
    );
  }
}

// ── Grid Item ─────────────────────────────────────────────────────────────────
class _GridItem extends StatelessWidget {
  final PrimeWarehouse w;
  final bool isSelected;
  final bool isAr;
  final VoidCallback onTap;

  const _GridItem({
    required this.w,
    required this.isSelected,
    required this.isAr,
    required this.onTap,
  });

  Color _getEmirateColor(String id) {
    switch (id) {
      case 'dxb':
        return const Color(0xFF1E50FF); // Dubai Cobalt
      case 'auh':
        return const Color(0xFF0A192F); // Abu Dhabi Navy
      case 'shj':
        return const Color(0xFF0D9488); // Sharjah Teal
      case 'aln':
        return const Color(0xFFD97706); // Al Ain Amber
      default:
        return AppColors.bluePrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emirateColor = _getEmirateColor(w.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.bluePrimary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.bluePrimary.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.blueGlow,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon badge + Selection pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.bluePrimary
                            : emirateColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        w.icon,
                        color: isSelected ? Colors.white : emirateColor,
                        size: 18,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.bluePrimary
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                // Middle: Emirate Name + Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAr ? w.nameAr : w.nameEn,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.bluePrimary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        if (w.id == 'dxb') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E50FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HOT',
                              style: TextStyle(
                                color: Color(0xFF1E50FF),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? w.subtitleAr : w.subtitleEn,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textSecondary
                            : Colors.grey.shade500,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // Bottom: Capacity tag pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.bluePrimary.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 11,
                        color: isSelected
                            ? AppColors.bluePrimary
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${w.totalShelves} ${isAr ? "رف متاح" : "Shelves"}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.bluePrimary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Rental Config Card ─────────────────────────────────────────────────────────
class _RentalConfigCard extends StatelessWidget {
  final PrimeWarehouse warehouse;
  final BookingConfig config;
  final bool isAr;
  final int availableShelves;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;

  const _RentalConfigCard({
    required this.warehouse,
    required this.config,
    required this.isAr,
    required this.availableShelves,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final int maxShelves = availableShelves.clamp(1, 100);
    if (config.shelves > maxShelves) {
      config.shelves = maxShelves;
    }
    final breakdown = config.calculateBreakdown();
    final fmt = NumberFormat.currency(symbol: 'AED ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        children: [
          // ── Card Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.blueGlow,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(warehouse.icon,
                      color: AppColors.bluePrimary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? warehouse.nameAr : warehouse.nameEn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isAr
                            ? 'الرفوف المتاحة: $availableShelves'
                            : 'Available shelves: $availableShelves',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Live price chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fmt.format(breakdown.total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // ── Capacity Sliders ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                _QuickPresetChips(
                  currentShelves: config.shelves,
                  onSelect: (val) {
                    config.shelves = val;
                    onUpdate();
                  },
                ),
                const SizedBox(height: 6),
                _SliderRow(
                  label: AppLocalizations.of(context)!.shelvesLabelSimple,
                  value: '${config.shelves}',
                  min: 1,
                  max: maxShelves.toDouble(),
                  current: config.shelves.toDouble(),
                  activeColor: AppColors.bluePrimary,
                  onChanged: (v) {
                    config.shelves = v.toInt();
                    onUpdate();
                  },
                ),
                const SizedBox(height: 8),
                _SliderRow(
                  label: AppLocalizations.of(context)!.monthsLabel,
                  value: '${config.durationMonths}',
                  min: 1,
                  max: 12,
                  current: config.durationMonths.toDouble(),
                  activeColor: AppColors.blueMid,
                  onChanged: (v) {
                    config.durationMonths = v.toInt();
                    onUpdate();
                  },
                ),
                const SizedBox(height: 10),
                _OversizedCargoGuardCard(
                  shelvesCount: config.shelves,
                  onAutoAdjustShelves: (minShelves) {
                    config.shelves = minShelves;
                    onUpdate();
                  },
                ),
                const SizedBox(height: 10),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),
                _WorkersControl(config: config, onUpdate: onUpdate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OversizedCargoGuardCard extends StatefulWidget {
  final int shelvesCount;
  final ValueChanged<int> onAutoAdjustShelves;

  const _OversizedCargoGuardCard({
    required this.shelvesCount,
    required this.onAutoAdjustShelves,
  });

  @override
  State<_OversizedCargoGuardCard> createState() => _OversizedCargoGuardCardState();
}

class _OversizedCargoGuardCardState extends State<_OversizedCargoGuardCard> {
  final TextEditingController _weightController = TextEditingController(text: '20');
  final TextEditingController _volumeController = TextEditingController(text: '0.3');

  int get _minShelvesRequired {
    final weight = double.tryParse(_weightController.text) ?? 20.0;
    final volume = double.tryParse(_volumeController.text) ?? 0.3;

    final reqW = (weight / 30.0).ceil();
    final reqV = (volume / 0.5).ceil();

    final maxReq = reqW > reqV ? reqW : reqV;
    return maxReq < 1 ? 1 : maxReq;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOversized = _minShelvesRequired > widget.shelvesCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOversized ? Colors.amber.shade50 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOversized ? Colors.amber.shade300 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOversized ? Icons.warning_amber_rounded : Icons.fitness_center_rounded,
                size: 16,
                color: isOversized ? Colors.amber.shade900 : AppColors.bluePrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Cargo Dimensions & Weight Guard (Max 30kg / 0.5m³)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOversized ? Colors.amber.shade900 : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Total Weight (kg)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _volumeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Volume (m³)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (isOversized) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Oversized Cargo: Requires minimum $_minShelvesRequired shelves or Bulk Floor Storage.',
              style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                label: Text(
                  'Auto-allocate $_minShelvesRequired Adjacent Shelves',
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () => widget.onAutoAdjustShelves(_minShelvesRequired),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick Preset Chips ──────────────────────────────────────────────────────────
class _QuickPresetChips extends StatelessWidget {
  final int currentShelves;
  final ValueChanged<int> onSelect;

  const _QuickPresetChips({required this.currentShelves, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final presets = [
      {'label': '5 Shelves (SME)', 'count': 5},
      {'label': '15 Shelves (Growth)', 'count': 15},
      {'label': '50 Shelves (Full Bay)', 'count': 50},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((p) {
          final count = p['count'] as int;
          final isSelected = currentShelves == count;
          return Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 4),
            child: ChoiceChip(
              label: Text(
                p['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.bluePrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.bluePrimary,
              backgroundColor: AppColors.blueGlow,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              side: BorderSide(
                color: isSelected ? AppColors.bluePrimary : AppColors.border,
              ),
              onSelected: (_) => onSelect(count),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Slider Row ─────────────────────────────────────────────────────────────────
class _SliderRow extends StatelessWidget {
  final String label, value;
  final double min, max, current;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.current,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blueGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            trackHeight: 5,
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: activeColor,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ── Workers Control ────────────────────────────────────────────────────────────
class _WorkersControl extends StatelessWidget {
  final BookingConfig config;
  final VoidCallback onUpdate;

  const _WorkersControl({required this.config, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final workerTotal = config.workerCount * 50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blueGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_outline_rounded,
                    size: 18, color: AppColors.bluePrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.addWorkersLabel,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              Switch(
                value: config.addWorkers,
                activeThumbColor: AppColors.bluePrimary,
                activeTrackColor: AppColors.blueMid,
                onChanged: (v) {
                  config.addWorkers = v;
                  if (v && config.workerCount < 1) {
                    config.workerCount = 1;
                  }
                  onUpdate();
                },
              ),
            ],
          ),
          if (config.addWorkers) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Number of Workers',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    _CounterButton(
                      icon: Icons.remove,
                      onPressed: config.workerCount > 1
                          ? () {
                              config.workerCount--;
                              onUpdate();
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${config.workerCount}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    _CounterButton(
                      icon: Icons.add,
                      onPressed: config.workerCount < 20
                          ? () {
                              config.workerCount++;
                              onUpdate();
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warehouse preparation: ${config.workerCount} worker${config.workerCount > 1 ? "s" : ""}  +AED $workerTotal',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CounterButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? AppColors.blueGlow : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? AppColors.blueMid.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? AppColors.bluePrimary : Colors.grey,
        ),
      ),
    );
  }
}

// ── Visual Warehouse Showcase (Empty State Replacement) ───────────────────────
class _VisualWarehouseShowcase extends StatelessWidget {
  final List<PrimeWarehouse> warehouses;
  final bool isAr;
  final Function(String id) onSelectWarehouse;

  const _VisualWarehouseShowcase({
    required this.warehouses,
    required this.isAr,
    required this.onSelectWarehouse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        // ── 1. Featured Flagship Hub Showcase Card ─────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF071A38),
                Color(0xFF003C8E),
                Color(0xFF1E50FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF003C8E).withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decorative circle
              Positioned(
                right: -25,
                top: -25,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFF38BDF8), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'المستودع الرئيسي الموصى به' : 'FLAGSHIP FACILITY',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isAr ? '200 رف متاح' : '200 Shelves Live',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'مستودع دبي المركزي الذكي (القوز 3)' : 'Dubai Central Smart Hub (Al Quoz 3)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'موقع استراتيجي بالقرب من شارع الشيخ زايد مع مراقبة أمنية 24/7 ورفوف تخزين عالية التحمل'
                          : 'Prime location off SZR with 24/7 CCTV, high-capacity shelving & instant gate pass entry.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Highlights row
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ShowcasePill(icon: Icons.shelves, label: isAr ? 'رفوف قياسية' : 'Standard Shelves'),
                        _ShowcasePill(icon: Icons.bolt_rounded, label: isAr ? 'حجز فوري' : 'Instant Hold'),
                        _ShowcasePill(icon: Icons.security_rounded, label: isAr ? 'تأمين شامل' : '100% Insured'),
                        _ShowcasePill(icon: Icons.receipt_long_rounded, label: isAr ? 'شامل الضريبة 5%' : 'FTA TRN Verified'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => onSelectWarehouse('dxb'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.bluePrimary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.touch_app_rounded, size: 18, color: AppColors.bluePrimary),
                        label: Text(
                          isAr ? 'اختر مستودع دبي وابدأ التخصيص ⚡' : 'Select Dubai Hub & Configure ⚡',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.bluePrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── 2. Why Choose NXN Warehouses Visual Grid ───────────────────────────
        Text(
          isAr ? 'مميزات شبكة مستودعات NXN' : 'Why Businesses Choose NXN Hubs',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _FeatureTile(
              icon: Icons.speed_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              title: isAr ? 'حجز فوري 10 دقائق' : '10-Min Hold Guarantee',
              desc: isAr ? 'تثبيت السعر والرفوف دون تأخير' : 'Locks capacity & pricing instantly without risk',
            ),
            _FeatureTile(
              icon: Icons.aspect_ratio_rounded,
              iconBg: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF16A34A),
              title: isAr ? 'مرونة التوسع' : 'Flexible Space Scaling',
              desc: isAr ? 'زيادة أو تقليص الرفوف شهرياً' : 'Scale shelf capacity easily on a monthly basis',
            ),
            _FeatureTile(
              icon: Icons.qr_code_scanner_rounded,
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFEA580C),
              title: isAr ? 'تصريح مرور رقمي' : 'Instant Dock Gate Pass',
              desc: isAr ? 'دخول مباشر لسائقي التوصيل والشحن' : 'QR token for drivers, zero gate queueing',
            ),
            _FeatureTile(
              icon: Icons.account_balance_rounded,
              iconBg: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF0284C7),
              title: isAr ? 'فواتير ضريبية معتمدة' : 'FTA Compliant VAT',
              desc: isAr ? 'فواتير رسمية متوافقة مع الأنظمة' : 'Fully registered TRN: 100492819200003',
            ),
          ],
        ),
      ],
    );
  }
}

class _ShowcasePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ShowcasePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String desc;

  const _FeatureTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.grey.shade600,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom Quote Bar ────────────────────────────────────────────────────────────
class _BottomQuoteBar extends StatelessWidget {
  final AppLocalizations l10n;
  final double grandTotal;
  final NumberFormat currencyFormat;
  final VoidCallback onBook;

  const _BottomQuoteBar({
    required this.l10n,
    required this.grandTotal,
    required this.currencyFormat,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003C8E).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.grandTotalSimple,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    currencyFormat.format(grandTotal),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.bluePrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(l10n.bookNow,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quote Dialog ───────────────────────────────────────────────────────────────
class _QuoteDialog extends StatelessWidget {
  final List<PrimeWarehouse> warehouses;
  final Map<String, BookingConfig> configs;
  final NumberFormat currencyFormat;
  final bool isAr;
  final double grandTotal;

  const _QuoteDialog({
    required this.warehouses,
    required this.configs,
    required this.currencyFormat,
    required this.isAr,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blueGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.bluePrimary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Quote Summary",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Per-warehouse breakdowns
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: warehouses.map((w) {
                    final config = configs[w.id]!;
                    final breakdown = config.calculateBreakdown();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(w.icon,
                                  size: 14, color: AppColors.bluePrimary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${isAr ? w.nameAr : w.nameEn} Central Warehouse",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _QuoteRow("Shelves", "${config.shelves}"),
                          if (config.addWorkers)
                            _QuoteRow("Workers", "${config.workerCount} (AED ${config.workerCount * 50})"),
                          _QuoteRow("Subtotal (mo)",
                              currencyFormat.format(breakdown.subtotal)),
                          _QuoteRow("Platform fee (mo)",
                              currencyFormat.format(breakdown.platformFee)),
                          _QuoteRow(
                              "VAT (mo)", currencyFormat.format(breakdown.vat)),
                          Divider(color: AppColors.border, height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total (mo)",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                currencyFormat.format(breakdown.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.bluePrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Grand Total Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.blueGlow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Grand Total',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormat.format(grandTotal),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bluePrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                "TRN: 100492819200003 • Inclusive of 5% UAE VAT (FTA Compliant)",
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Close"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleBooking(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Continue",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                        ],
                      ),
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

  void _handleBooking(BuildContext context) async {
    final selectedWarehouseIds =
        configs.keys.where((k) => configs[k]!.isSelected).toList();
    final metadataMap = <String, dynamic>{
      'warehouseIds': selectedWarehouseIds,
    };
    for (var wId in selectedWarehouseIds) {
      metadataMap['shelves_$wId'] = configs[wId]!.shelves;
      metadataMap['duration_$wId'] = configs[wId]!.durationMonths;
      metadataMap['workers_$wId'] = configs[wId]!.addWorkers ? configs[wId]!.workerCount : 0;
    }

    final newInvoice = Invoice(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      number:
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      warehouseName: 'Single/Multi Warehouse Booking',
      date: DateTime.now(),
      amount: grandTotal * 0.95,
      vat: grandTotal * 0.05,
      paid: false,
      type: InvoiceType.rental,
      metaData: metadataMap,
    );

    try {
      await MarketplaceService().createInvoice(newInvoice);
    } catch (e) {
      debugPrint('Error saving invoice: $e');
    }

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutPage(invoice: newInvoice)));
    }
  }
}

// ── Quote Row ──────────────────────────────────────────────────────────────────
class _QuoteRow extends StatelessWidget {
  final String label, value;
  const _QuoteRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
