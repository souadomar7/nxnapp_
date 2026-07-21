import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'checkout_page.dart';
import '../models/invoice.dart';
import '../services/marketplace_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/brand_logo.dart';

// ==============================================================================
// 1. THEME & CONSTANTS (Compact)
// ==============================================================================

class BookingTheme {
  static const Color primary = Color(0xFF1A47B8);
  static const Color primaryDark = Color(0xFF102A70);
  static const Color accent = Color(0xFFF4B400);
  static const Color background = Color(0xFFF5F6FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textGrey = Color(0xFFA4B0BE);
  static const Color cardShadow = Color(0x0D000000);

  // Reduced font size for tighter UI
  static TextStyle get titleStyle => const TextStyle(
      fontSize: 14, fontWeight: FontWeight.bold, color: primary, letterSpacing: 0.5
  );
}

// ==============================================================================
// 2. DATA MODELS & LOGIC
// ==============================================================================

class PrimeWarehouse {
  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;

  const PrimeWarehouse({
    required this.id,
    required this.nameEn,
    required this.nameAr,
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

  BookingConfig({
    this.isSelected = false,
    this.shelves = 5,
    this.durationMonths = 1,
    this.addWorkers = false,
  });

  /// PRD §3 Billing Rules:
  /// - Base rate:   100 AED × shelves × months
  /// - Worker fee:  +50 AED flat per request (NOT per worker, NOT per month)
  /// - Platform 5%: applied on (base + workerFee)
  /// - VAT 5%:      applied on (base + workerFee + platformFee)
  PriceBreakdown calculateBreakdown() {
    final double baseCost = 100.0 * shelves * durationMonths;
    const double workerFlatFee = 50.0; // PRD §3: flat fee, not per-worker
    final double workerFee = addWorkers ? workerFlatFee : 0.0;
    final double subtotal = baseCost + workerFee;
    final double platformFee = subtotal * 0.05;
    final double vat = (subtotal + platformFee) * 0.05;
    final double total = subtotal + platformFee + vat;

    return PriceBreakdown(
        subtotal: subtotal,
        platformFee: platformFee,
        vat: vat,
        total: total);
  }
}

// ==============================================================================
// 3. MAIN PAGE
// ==============================================================================

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final List<PrimeWarehouse> _warehouses = [
    const PrimeWarehouse(id: 'dxb', nameEn: 'Dubai', nameAr: 'دبي', icon: Icons.business),
    const PrimeWarehouse(id: 'auh', nameEn: 'Abu Dhabi', nameAr: 'أبو ظبي', icon: Icons.location_city),
    const PrimeWarehouse(id: 'shj', nameEn: 'Sharjah', nameAr: 'الشارقة', icon: Icons.mosque),
    const PrimeWarehouse(id: 'aln', nameEn: 'Al Ain', nameAr: 'العين', icon: Icons.landscape),
  ];

  final Map<String, BookingConfig> _configs = {};

  double get _grandTotal => _configs.values.where((c) => c.isSelected)
      .fold(0, (sum, c) => sum + c.calculateBreakdown().total);

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
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 0);
    // Reduced bottom padding
    final bottomPadding = _selectedCount > 0 ? 90.0 : 16.0;

    return Scaffold(
      backgroundColor: BookingTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _BookingHeader(l10n: l10n, isAr: isAr),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: BookingTheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Slightly sharper
                  ),
                  transform: Matrix4.translationValues(0, -10, 0), // Adjusted overlap
                  padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding), // Increased top padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: l10n.step1Title),
                      const SizedBox(height: 8),

                      _WarehouseGrid(
                        warehouses: _warehouses,
                        configs: _configs,
                        isAr: isAr,
                        onToggle: (id) => setState(() {
                          _configs[id]!.isSelected = !_configs[id]!.isSelected;
                        }),
                      ),

                      const SizedBox(height: 16),

                      if (_selectedCount > 0) ...[
                        _SectionTitle(title: l10n.step2CustomizeSpace),
                        const SizedBox(height: 8),
                        ..._warehouses.where((w) => _configs[w.id]!.isSelected).map(
                              (w) => _RentalConfigCard(
                            warehouse: w,
                            config: _configs[w.id]!,
                            isAr: isAr,
                            onUpdate: () => setState(() {}),
                            onRemove: () => setState(() => _configs[w.id]!.isSelected = false),
                          ),
                        ),
                      ] else
                        _EmptyState(l10n: l10n),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_selectedCount > 0)
            Positioned(
              bottom: 0, left: 0, right: 0,
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
        warehouses: _warehouses.where((w) => _configs[w.id]!.isSelected).toList(),
        configs: _configs,
        currencyFormat: fmt,
        isAr: isAr,
        grandTotal: _grandTotal,
      ),
    );
  }
}

// ==============================================================================
// 4. SUB-WIDGETS (UI COMPONENTS - COMPACT)
// ==============================================================================

class _BookingHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isAr;

  const _BookingHeader({required this.l10n, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120, // Further Reduced from 140
      pinned: true,
      backgroundColor: BookingTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Tighter padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Center(child: BrandLogo(height: 28, isLight: true)), // Smaller Logo
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(l10n.welcomeUser("Suad"), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), // Smaller font
                        const SizedBox(width: 8),
                        const Text("👋", style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        isAr ? "اعثر على مخزن للإيجار اليوم" : "Find a warehouse to rent today",
                        style: const TextStyle(color: Colors.white70, fontSize: 12), // Smaller font
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: BookingTheme.titleStyle);
  }
}

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
      childAspectRatio: 2.2, // Taller boxes for better icon support
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: warehouses.map((w) {
        final isSelected = configs[w.id]!.isSelected;
        return _GridItem(w: w, isSelected: isSelected, isAr: isAr, onTap: () => onToggle(w.id));
      }).toList(),
    );
  }
}

class _GridItem extends StatelessWidget {
  final PrimeWarehouse w;
  final bool isSelected;
  final bool isAr;
  final VoidCallback onTap;

  const _GridItem({required this.w, required this.isSelected, required this.isAr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? BookingTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: isSelected ? 3 : 1,
      shadowColor: BookingTheme.cardShadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? BookingTheme.primary : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : BookingTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  w.icon,
                  color: isSelected ? Colors.white : BookingTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? w.nameAr : w.nameEn,
                  style: TextStyle(
                    color: isSelected ? Colors.white : BookingTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RentalConfigCard extends StatelessWidget {
  final PrimeWarehouse warehouse;
  final BookingConfig config;
  final bool isAr;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;

  const _RentalConfigCard({
    required this.warehouse,
    required this.config,
    required this.isAr,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: BookingTheme.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Tighter padding
            decoration: BoxDecoration(
              color: BookingTheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(warehouse.icon, color: BookingTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  isAr ? warehouse.nameAr : warehouse.nameEn,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: BookingTheme.primaryDark),
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
          // Sliders & Toggles
          Padding(
            padding: const EdgeInsets.all(12), // Reduced padding
            child: Column(
              children: [
                _SliderRow(
                  label: AppLocalizations.of(context)!.shelvesLabelSimple,
                  value: '${config.shelves}',
                  min: 1, max: 50,
                  current: config.shelves.toDouble(),
                  activeColor: BookingTheme.primary,
                  onChanged: (v) { config.shelves = v.toInt(); onUpdate(); },
                ),
                const SizedBox(height: 8), // Reduced gap
                _SliderRow(
                  label: AppLocalizations.of(context)!.monthsLabel,
                  value: '${config.durationMonths}',
                  min: 1, max: 12,
                  current: config.durationMonths.toDouble(),
                  activeColor: BookingTheme.accent,
                  onChanged: (v) { config.durationMonths = v.toInt(); onUpdate(); },
                ),
                const Divider(height: 16), // Thinner divider
                _WorkersControl(config: config, onUpdate: onUpdate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label, value;
  final double min, max, current;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _SliderRow({required this.label, required this.value, required this.min, required this.max, required this.current, required this.activeColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(
          height: 24, // Reduced slider container height
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10), // Smaller thumb
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackHeight: 6, // Thinner track
            ),
            child: Slider(value: current, min: min, max: max, divisions: (max-min).toInt(), activeColor: activeColor, inactiveColor: Colors.grey[200], onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

class _WorkersControl extends StatelessWidget {
  final BookingConfig config;
  final VoidCallback onUpdate;

  const _WorkersControl({required this.config, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Tighter
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, size: 20, color: BookingTheme.primary), // Smaller icon
              const SizedBox(width: 10),
              Expanded(child: Text(AppLocalizations.of(context)!.addWorkersLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              Transform.scale(
                scale: 0.7, // Smaller Switch
                child: Switch(
                  value: config.addWorkers,
                  activeTrackColor: BookingTheme.primary,
                  onChanged: (v) { config.addWorkers = v; onUpdate(); },
                ),
              ),
            ],
          ),
          if (config.addWorkers) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Warehouse preparation included  +AED 50',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600),
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



class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          children: [
            Icon(Icons.warehouse_outlined, size: 48, color: Colors.grey.shade300), // Smaller Icon
            const SizedBox(height: 8),
            Text(l10n.noEmirateSelected, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _BottomQuoteBar extends StatelessWidget {
  final AppLocalizations l10n;
  final double grandTotal;
  final NumberFormat currencyFormat;
  final VoidCallback onBook;

  const _BottomQuoteBar({required this.l10n, required this.grandTotal, required this.currencyFormat, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced Padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [BoxShadow(color: BookingTheme.cardShadow, blurRadius: 15, offset: Offset(0, -3))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.grandTotalSimple, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(currencyFormat.format(grandTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: BookingTheme.primary)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: BookingTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), // Smaller Button padding
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(l10n.bookNow, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteDialog extends StatelessWidget {
  final List<PrimeWarehouse> warehouses;
  final Map<String, BookingConfig> configs;
  final NumberFormat currencyFormat;
  final bool isAr;
  final double grandTotal;

  const _QuoteDialog({required this.warehouses, required this.configs, required this.currencyFormat, required this.isAr, required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Combined Quote Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BookingTheme.textDark)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: warehouses.map((w) {
                    final config = configs[w.id]!;
                    final breakdown = config.calculateBreakdown();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${isAr ? w.nameAr : w.nameEn} Central Warehouse", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 6),
                          _QuoteRow("Shelves", "${config.shelves}"),
                          _QuoteRow("Subtotal (mo)", currencyFormat.format(breakdown.subtotal)),
                          _QuoteRow("Platform fee (mo)", currencyFormat.format(breakdown.platformFee)),
                          _QuoteRow("VAT (mo)", currencyFormat.format(breakdown.vat)),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total (mo)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BookingTheme.textDark)),
                              Text(currencyFormat.format(breakdown.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BookingTheme.textDark)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BookingTheme.textGrey)))),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleBooking(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: BookingTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text("Continue to payment", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBooking(BuildContext context) async {
    final selectedWarehouseIds = configs.keys.where((k) => configs[k]!.isSelected).toList();
    final metadataMap = <String, dynamic>{
      'warehouseIds': selectedWarehouseIds,
    };
    for (var wId in selectedWarehouseIds) {
      metadataMap['shelves_$wId'] = configs[wId]!.shelves;
      metadataMap['duration_$wId'] = configs[wId]!.durationMonths;
    }

    final newInvoice = Invoice(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      number: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(invoice: newInvoice)));
    }
  }
}

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
          Text(label, style: const TextStyle(fontSize: 12, color: BookingTheme.textGrey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 12, color: BookingTheme.textGrey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}