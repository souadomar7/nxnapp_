import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_page.dart'; 
import '../models/invoice.dart';
import '../services/marketplace_service.dart'; // Import service
// import 'package:flutter_svg/flutter_svg.dart'; // Uncomment if using SVG logo
// import 'package:flutter_svg/flutter_svg.dart'; // Uncomment if using SVG logo

// --- THEME COLORS (Based on Screenshot) ---
class BookingColors {
  static const Color primary = Color(0xFF1A47B8); // NXN Blue
  static const Color primaryDark = Color(0xFF102A70);
  static const Color accent = Color(0xFFF4B400); // Gold/Yellow for greeting
  static const Color background = Color(0xFFF5F6FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textGrey = Color(0xFFA4B0BE);
}

// --- DATA MODELS ---
class PrimeWarehouse {
  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;

  PrimeWarehouse({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
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
    this.shelves = 5, // Default start
    this.durationMonths = 1,
    this.addWorkers = false,
    this.workerCount = 1,
  });

  double get totalCost {
    if (!isSelected) return 0;
    // Centralized Logic via Service (Simulating API Call)
    return MarketplaceService().calculateRentalPrice(shelves, durationMonths, addWorkers, workerCount);
  }
}

// --- MAIN PAGE ---
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // The 4 Prime Locations
  final List<PrimeWarehouse> _warehouses = [
    PrimeWarehouse(id: 'dxb', nameEn: 'Dubai', nameAr: 'دبي', icon: Icons.business),
    PrimeWarehouse(id: 'auh', nameEn: 'Abu Dhabi', nameAr: 'أبو ظبي', icon: Icons.location_city),
    PrimeWarehouse(id: 'shj', nameEn: 'Sharjah', nameAr: 'الشارقة', icon: Icons.mosque),
    PrimeWarehouse(id: 'aln', nameEn: 'Al Ain', nameAr: 'العين', icon: Icons.landscape),
  ];

  final Map<String, BookingConfig> _configs = {};

  @override
  void initState() {
    super.initState();
    for (var w in _warehouses) {
      _configs[w.id] = BookingConfig();
    }
  }

  double get _grandTotal => _configs.values.fold(0, (sum, c) => sum + c.totalCost);
  int get _selectedCount => _configs.values.where((c) => c.isSelected).length;
  @override
  Widget build(BuildContext context) {
    // Detect Language from context (Assuming generic check for now)
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final currencyFormat = NumberFormat.currency(symbol: 'AED ', decimalDigits: 0);
    final bottomPadding = _selectedCount > 0 ? 100.0 : 20.0;

    return Scaffold(
      backgroundColor: BookingColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Sliver App Bar (Scrollable Header)
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: BookingColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Text(
                                "NXN",
                                style: TextStyle(color: BookingColors.primary, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                isAr ? "مرحباً سعاد!" : "Welcome Suad!",
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Text("👋", style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAr ? "اعثر على مخزن للإيجار اليوم" : "Find a warehouse to rent today",
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Content List
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: BookingColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0), // Overlap effect
                  padding: EdgeInsets.fromLTRB(20, 30, 20, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(isAr ? 'الخطوة 1 - اختر الإمارة' : 'Step 1 - Choose Emirate'),
                      const SizedBox(height: 12),
                      _buildLocationGrid(isAr),

                      const SizedBox(height: 30),

                      if (_selectedCount > 0) ...[
                        _sectionTitle(isAr ? 'الخطوة 2 - تخصيص المساحة' : 'Step 2 - Customize Space'),
                        const SizedBox(height: 12),
                        ..._warehouses.where((w) => _configs[w.id]!.isSelected).map(
                              (w) => _buildConfigCard(w, _configs[w.id]!, isAr),
                            ),
                      ] else 
                         _buildEmptyState(isAr),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. Floating Quote Bar
          if (_selectedCount > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomQuoteBar(currencyFormat, isAr),
            ),
        ],
      ),
    );
  }

  // Helper moved inside build or kept, but _buildHeader is gone.
  // ... other widgets use existing methods ...

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: BookingColors.textDark,
      ),
    );
  }

  Widget _buildLocationGrid(bool isAr) {
    if (_warehouses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Error: No location data available."),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: _warehouses.map((w) {
        // Safety check for config
        if (!_configs.containsKey(w.id)) {
          return const SizedBox(); // Should not happen
        }

        final isSelected = _configs[w.id]!.isSelected;
        
        return Material(
          color: isSelected ? BookingColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: isSelected ? 4 : 1, // Add slight elevation to unselected too to make it pop
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: InkWell(
            onTap: () {
              setState(() {
                _configs[w.id]!.isSelected = !isSelected;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? BookingColors.primary : Colors.grey.shade400, // Darker grey
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isAr ? w.nameAr : w.nameEn,
                    style: TextStyle(
                      color: isSelected ? Colors.white : BookingColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfigCard(PrimeWarehouse w, BookingConfig c, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header: Location Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BookingColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(w.icon, color: BookingColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  isAr ? w.nameAr : w.nameEn,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: BookingColors.primaryDark),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => setState(() => c.isSelected = false),
                ),
              ],
            ),
          ),
          
          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Shelves Slider
                _controlRow(
                  label: isAr ? 'عدد الرفوف' : 'Shelves',
                  value: '${c.shelves}',
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16), // Big Thumb
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                      trackHeight: 12, // Thick Track
                    ),
                    child: Slider(
                      value: c.shelves.toDouble(),
                      min: 1,
                      max: 50,
                      activeColor: BookingColors.primary,
                      inactiveColor: Colors.grey[200],
                      divisions: 49,
                      onChanged: (v) => setState(() => c.shelves = v.toInt()),
                    ),
                  ),
                ),
                const SizedBox(height: 24), // More space
                
                // Duration Slider
                _controlRow(
                  label: isAr ? 'المدة (أشهر)' : 'Months',
                  value: '${c.durationMonths}',
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16), // Big Thumb
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                      trackHeight: 12, // Thick Track
                    ),
                    child: Slider(
                      value: c.durationMonths.toDouble(),
                      min: 1,
                      max: 12,
                      activeColor: BookingColors.accent,
                      inactiveColor: Colors.grey[200],
                      divisions: 11,
                      onChanged: (v) => setState(() => c.durationMonths = v.toInt()),
                    ),
                  ),
                ),
                
                const Divider(height: 40),
                
                // Workers Toggle
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 28, color: Colors.grey[600]), // Bigger Icon
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr ? 'إضافة عمال؟ (+50 درهم/عامل)' : 'Add Workers? (+50 AED/ea)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Transform.scale(
                      scale: 1.2, // Bigger Switch
                      child: Switch(
                        value: c.addWorkers,
                        activeTrackColor: BookingColors.primary,
                        onChanged: (v) => setState(() => c.addWorkers = v),
                      ),
                    ),
                  ],
                ),
                
                if (c.addWorkers)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _roundBtn(Icons.remove, () => setState(() => c.workerCount > 1 ? c.workerCount-- : null)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${c.workerCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      _roundBtn(Icons.add, () => setState(() => c.workerCount < 10 ? c.workerCount++ : null)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlRow({required String label, required String value, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 30, child: child), // Compact Slider
      ],
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.warehouse_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              isAr ? "لم يتم اختيار إمارة" : "No Emirate Selected",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomQuoteBar(NumberFormat format, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? "الإجمالي" : "Grand Total",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  format.format(_grandTotal),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BookingColors.primary),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                 final newInvoice = Invoice(
                    id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                    number: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    warehouseName: 'Single/Multi Warehouse Booking', // Simplified
                    date: DateTime.now(),
                    amount: _grandTotal * 0.95, // Subtotal approx
                    vat: _grandTotal * 0.05,
                    paid: false,
                    type: InvoiceType.rental,
                    metaData: {
                      'warehouseIds': _configs.keys.where((k) => _configs[k]!.isSelected).toList(),
                      // Just taking the first one for simplicity in this aggregate invoice, 
                      // or we could handle multiple subscriptions in the service.
                      // For this demo, let's assume we pass the primary one or map them later.
                      'primaryWarehouseId': _configs.keys.firstWhere((k) => _configs[k]!.isSelected), 
                      'shelves': _configs.values.firstWhere((c) => c.isSelected).shelves,
                      'duration': _configs.values.firstWhere((c) => c.isSelected).durationMonths,
                    },
                 );
                 
                 // Persist to DB
                 try {
                   await MarketplaceService().createInvoice(newInvoice);
                 } catch (e) {
                   debugPrint('Error saving invoice: $e');
                   // optionally show error or proceed with ephemeral
                 }

                 if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PaymentsPage(
                            initialInvoice:
                                newInvoice)), // Still passing it for immediate display focus
                  );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BookingColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20), // Large pill button
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text(
                isAr ? "احجز الآن" : "Book Now",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
