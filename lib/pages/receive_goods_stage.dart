import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../services/marketplace_service.dart';
import '../data/receive_result.dart';
import '../theme.dart';
import 'smart_inventory_stage.dart';
import '../services/pdf_export_service.dart';
import 'document_preview_page.dart';

class ReceiveColors {
  static const primary = AppColors.bluePrimary;
  static const background = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textSub = Color(0xFF64748B);
  static const cardBorder = Color(0xFFE2E8F0);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
}

class ReceiveGoodsStagePageEN extends StatefulWidget {
  const ReceiveGoodsStagePageEN({super.key});

  @override
  State<ReceiveGoodsStagePageEN> createState() => _ReceiveGoodsStagePageENState();
}

class _ReceiveGoodsStagePageENState extends State<ReceiveGoodsStagePageEN> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  // Current Step (0: Warehouse Hub & Temp, 1: Schedule & Truck, 2: Cargo & Workers, 3: Gate Pass Confirmation)
  int _currentStep = 0;

  // Step 1: Warehouse Hub
  String _selectedWarehouse = 'Dubai Central Warehouse';
  String _selectedStorageMode = 'Standard Shelving';

  // Step 2: Schedule & Freight Info
  DateTime? _scheduledDate;
  String _selectedTimeSlot = '09:00 AM - 12:00 PM';
  final TextEditingController _carrierCtrl = TextEditingController();
  final TextEditingController _truckPlateCtrl = TextEditingController();

  // Step 3: Cargo Manifest & Workers
  int _itemCount = 50;
  int _boxCount = 5;
  int _workers = 1;
  final TextEditingController _productNameCtrl = TextEditingController(text: 'General Merchandise Box');
  final TextEditingController _notesCtrl = TextEditingController();

  // Step 4: Output Gate Pass / Confirmation Result
  bool _isSubmitting = false;
  Map<String, dynamic>? _generatedGatePass;

  @override
  void dispose() {
    _carrierCtrl.dispose();
    _truckPlateCtrl.dispose();
    _productNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _submitInboundRequest() async {
    if (_scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'يرجى اختيار تاريخ تسليم البضائع للمستودع'
                : 'Please select a warehouse drop-off date.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await _marketplaceService.createInboundReceivingRequest(
      warehouseName: _selectedWarehouse,
      storageMode: _selectedStorageMode,
      scheduledDate: _scheduledDate!,
      timeSlot: _selectedTimeSlot,
      itemCount: _itemCount,
      boxCount: _boxCount,
      workers: _workers,
      productName: _productNameCtrl.text.trim(),
      carrierName: _carrierCtrl.text.trim(),
      truckPlate: _truckPlateCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _generatedGatePass = res;
      _currentStep = 3; // Advance to confirmation gate pass step
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade800,
        content: Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'تم إرسال طلب التزويد وإخطار مسؤول المستودع بنجاح! 🔔'
              : 'Inbound request submitted & Admin notified successfully! 🔔',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: ReceiveColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── 1. Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: ReceiveColors.primary,
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
                              child: const Icon(Icons.move_to_inbox_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'تجهيز واستلام البضائع' : 'Inbound Receiving & Prep',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr ? 'طلب رصيد تفريغ وتنبيه مسئول المستودع' : 'Schedule drop-off bay & notify warehouse admin',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
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

          // ─── 2. Stepper Progress Bar ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _stepIndicator(0, isAr ? 'المستودع' : 'Hub', isAr),
                  _stepLine(0),
                  _stepIndicator(1, isAr ? 'الموعد' : 'Schedule', isAr),
                  _stepLine(1),
                  _stepIndicator(2, isAr ? 'البضائع' : 'Cargo', isAr),
                  _stepLine(2),
                  _stepIndicator(3, isAr ? 'التأكيد' : 'Gate Pass', isAr),
                ],
              ),
            ),
          ),

          // ─── 3. Dynamic Step Content ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: _buildCurrentStepContent(isAr),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stepper Indicators ──────────────────────────────────────────────────
  Widget _stepIndicator(int stepIndex, String title, bool isAr) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    Color textColor = Colors.grey.shade500;
    if (isDone || isCurrent) {
      textColor = InventoryColors.textDark;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrent
                ? ReceiveColors.primary
                : isDone
                    ? Colors.green
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: (isCurrent || isDone) ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isDone ? Colors.green : Colors.grey.shade200,
      ),
    );
  }

  // ─── Step Router ─────────────────────────────────────────────────────────
  Widget _buildCurrentStepContent(bool isAr) {
    switch (_currentStep) {
      case 0:
        return _buildStep1WarehouseHub(isAr);
      case 1:
        return _buildStep2ScheduleAndFreight(isAr);
      case 2:
        return _buildStep3CargoAndWorkers(isAr);
      case 3:
        return _buildStep4GatePassConfirmation(isAr);
      default:
        return const SizedBox();
    }
  }

  // ─── Step 1: Select Warehouse Hub ─────────────────────────────────────────
  Widget _buildStep1WarehouseHub(bool isAr) {
    final hubs = [
      {'name': isAr ? 'مستودع دبي المركزي' : 'Dubai Central Warehouse', 'location': 'Dubai Industrial City', 'icon': Icons.location_city_rounded},
      {'name': isAr ? 'مستودع أبوظبي المركزي' : 'Abu Dhabi Central Hub', 'location': 'KIZAD Logistics Park', 'icon': Icons.location_on_rounded},
      {'name': isAr ? 'مستودع الشارقة الإقليمي' : 'Sharjah Regional Hub', 'location': 'Al Saja\'a Industrial Zone', 'icon': Icons.storefront_rounded},
      {'name': isAr ? 'مركز تجميع العين' : 'Al Ain Fulfillment Center', 'location': 'Niyadat Industrial Area', 'icon': Icons.warehouse_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الخطوة 1: اختر مستودع الاستلام' : 'Step 1: Select Fulfillment Hub',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: InventoryColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'حدد مركز NXN الوارد المخصص لتفريغ شحنتك وإصدار تصريح الدخول' : 'Choose destination warehouse for intake and gate pass clearance',
          style: const TextStyle(fontSize: 12, color: InventoryColors.textSub),
        ),
        const SizedBox(height: 20),

        // Hubs Cards
        Text(isAr ? 'مستودع الوارد' : 'Destination Warehouse Hub', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...hubs.map((h) {
          final name = h['name'] as String;
          final selected = _selectedWarehouse == name;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedWarehouse = name),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? ReceiveColors.primary : ReceiveColors.cardBorder, width: selected ? 2 : 1),
                  boxShadow: [
                    if (selected) BoxShadow(color: ReceiveColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(h['icon'] as IconData, color: selected ? ReceiveColors.primary : Colors.grey, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: selected ? ReceiveColors.primary : InventoryColors.textDark)),
                          Text(h['location'] as String, style: const TextStyle(fontSize: 11, color: InventoryColors.textSub)),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.check_circle_rounded, color: ReceiveColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 30),

        // Next Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: ReceiveColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAr ? 'المتابعة لتحديد الموعد والشاحنة' : 'Continue to Schedule & Carrier',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Icon(isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2: Schedule & Delivery Truck Info ──────────────────────────────
  Widget _buildStep2ScheduleAndFreight(bool isAr) {
    final slots = [
      '08:00 AM - 11:00 AM',
      '11:00 AM - 02:00 PM',
      '02:00 PM - 05:00 PM',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الخطوة 2: تحديد موعد وصول شاحنة التوريد' : 'Step 2: Schedule Inbound Drop-Off & Delivery Truck',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: InventoryColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'اختر تاريخ ووقت التنزيل وأدخل بيانات الناقل' : 'Select drop-off arrival date, time slot, and delivery vehicle info',
          style: const TextStyle(fontSize: 12, color: InventoryColors.textSub),
        ),
        const SizedBox(height: 20),

        // Date Picker Button
        Text(isAr ? 'تاريخ التوصيل والوصول' : 'Delivery Date *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now.add(const Duration(days: 1)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 60)),
            );
            if (picked != null) setState(() => _scheduledDate = picked);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _scheduledDate != null ? ReceiveColors.primary : ReceiveColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: ReceiveColors.primary, size: 22),
                const SizedBox(width: 14),
                Text(
                  _scheduledDate != null ? _fmtDate(_scheduledDate!) : (isAr ? 'انقر لاختيار تاريخ التوصيل...' : 'Click to select drop-off date...'),
                  style: TextStyle(
                    fontWeight: _scheduledDate != null ? FontWeight.bold : FontWeight.normal,
                    color: _scheduledDate != null ? InventoryColors.textDark : Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Time Slot Picker
        Text(isAr ? 'نافذة الوقت المتاحة' : 'Arrival Time Window', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: slots.map((s) {
            final selected = _selectedTimeSlot == s;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: selected,
                  selectedColor: ReceiveColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: selected ? Colors.white : InventoryColors.textDark),
                  onSelected: (_) => setState(() => _selectedTimeSlot = s),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Carrier & Vehicle Details
        Text(isAr ? 'بيانات الشاحنة والشركة الناقلة' : 'Delivery Truck & Carrier Info', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          controller: _carrierCtrl,
          decoration: InputDecoration(
            labelText: isAr ? 'اسم شركة الشحن (مثال: أرامكس / شحنة خاصة)' : 'Carrier Company (e.g. Aramex / Private Truck)',
            prefixIcon: const Icon(Icons.local_shipping_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _truckPlateCtrl,
          decoration: InputDecoration(
            labelText: isAr ? 'رقم لوحة الشاحنة (مثال: دبي 92810)' : 'Delivery Truck Plate (e.g. UAE-DXB-92810)',
            prefixIcon: const Icon(Icons.pin_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 30),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isAr ? 'السابق' : 'Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (_scheduledDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isAr ? 'يرجى اختيار تاريخ التوصيل أولاً' : 'Please select delivery date first.')),
                    );
                    return;
                  }
                  setState(() => _currentStep = 2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReceiveColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isAr ? 'التالي: تفاصيل البضائع' : 'Next: Cargo Manifest', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 3: Cargo Manifest & Workers Request ─────────────────────────────
  Widget _buildStep3CargoAndWorkers(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الخطوة 3: بيان المنتجات وطلب عمال التنزيل' : 'Step 3: Cargo Manifest & Offloading Workers Request',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: InventoryColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'حدد كمية المنتجات والكراتين المطلوبة للتفريغ' : 'Specify item counts, box quantities, and required offloading workers',
          style: const TextStyle(fontSize: 12, color: InventoryColors.textSub),
        ),
        const SizedBox(height: 20),

        // Product Name Input
        Text(
          isAr ? 'اسم المنتج الوارد *' : 'Product / Commodity Name *',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _productNameCtrl,
          decoration: InputDecoration(
            hintText: isAr ? 'أدخل اسم المنتج (مثال: قهوة باردة 500مل، زيت زيتون...)' : 'Enter product name (e.g. Cold Brew Coffee 500ml, Organic Honey Jar)',
            prefixIcon: const Icon(Icons.inventory_2_outlined, color: ReceiveColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 18),

        // Items & Boxes Counters
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ReceiveColors.cardBorder),
          ),
          child: Column(
            children: [
              _counterRow(
                title: isAr ? 'عدد القطع/المنتجات' : 'Estimated Item Units',
                subtitle: isAr ? 'إجمالي القطع الواردة للتخزين' : 'Total individual items for inventory',
                value: _itemCount,
                onAdd: () => setState(() => _itemCount += 10),
                onMin: () => setState(() => _itemCount = (_itemCount - 10).clamp(10, 5000)),
              ),
              const Divider(height: 24),
              _counterRow(
                title: isAr ? 'عدد الكراتين / المنصات' : 'Boxes / Pallets Count',
                subtitle: isAr ? 'عدد الطرود الكبيرة المسلمة' : 'Total outer boxes or shipping pallets',
                value: _boxCount,
                onAdd: () => setState(() => _boxCount += 1),
                onMin: () => setState(() => _boxCount = (_boxCount - 1).clamp(1, 500)),
              ),
              const Divider(height: 24),
              _counterRow(
                title: isAr ? 'طلب عمال للتفريغ (+50 درهم/عامل)' : 'Request Offloading Workers (+50 AED/worker)',
                subtitle: isAr ? 'عمال مخصصون لمساعدة السائق عند الرصيف' : 'Dedicated warehouse labor at the unloading bay',
                value: _workers,
                onAdd: () => setState(() => _workers += 1),
                onMin: () => setState(() => _workers = (_workers - 1).clamp(0, 10)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Notes
        Text(isAr ? 'تعليمات خاصة لمسئول المستودع' : 'Special Handling Notes for Warehouse Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: isAr ? 'مثال: زجاج قابل للكسر، يتطلب رافعة شوكية...' : 'e.g. Fragile glass bottles, requires forklift...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 30),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isAr ? 'السابق' : 'Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitInboundRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReceiveColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isAr ? 'إرسال وإخطار المستودع' : 'Submit & Notify Admin',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 4: Digital Inbound Gate Pass / Confirmation ─────────────────────
  Widget _buildStep4GatePassConfirmation(bool isAr) {
    final pass = _generatedGatePass ?? {};
    final storageNo = pass['storage_no'] ?? 'STO-992817';
    final bay = pass['bay'] ?? 'BAY-3';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Notice Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تم إرسال طلب التزويد وإخطار المستودع!' : 'Inbound Request Confirmed & Admin Notified!',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? 'تم حجز رصيد التفريغ وإرسال التنبيه الفوري لمسئول النظام.' : 'Unloading bay reserved & instant system alert pushed to admin.',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Digital Inbound Gate Pass Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ReceiveColors.primary.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: ReceiveColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Gate Pass Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'تصريح دخول شاحنة التوريد' : 'INBOUND GATE PASS',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ReceiveColors.primary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storageNo,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: InventoryColors.textDark),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blueGlow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 36, color: ReceiveColors.primary),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Details
              _infoRow(isAr ? 'رصيد التفريغ المحجوز' : 'Reserved Unloading Bay', bay, isHighlight: true),
              _infoRow(isAr ? 'المستودع' : 'Warehouse Hub', _selectedWarehouse),
              _infoRow(isAr ? 'تاريخ ووقت الوصول' : 'Scheduled Arrival', '${_scheduledDate != null ? _fmtDate(_scheduledDate!) : ""} ($_selectedTimeSlot)'),
              _infoRow(isAr ? 'فئة درجة الحرارة' : 'Storage Mode', _selectedStorageMode),
              _infoRow(isAr ? 'إجمالي الشحنة' : 'Total Shipment', '$_itemCount ${isAr ? "قطع" : "Units"} ($_boxCount ${isAr ? "كراتين" : "Boxes"})'),
              _infoRow(isAr ? 'عمال التنزيل المخصصون' : 'Assigned Workers', '$_workers (${isAr ? "عمال" : "Workers"})'),
              _infoRow(isAr ? 'بيانات الشاحنة والناقل' : 'Truck & Carrier', '${pass['carrier_name'] ?? _carrierCtrl.text} (${pass['truck_plate'] ?? _truckPlateCtrl.text})'),

              const SizedBox(height: 20),

              // Barcode Representation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.line_weight_rounded, size: 40, color: InventoryColors.textDark),
                    const SizedBox(height: 4),
                    Text(
                      '*$storageNo*$bay*',
                      style: const TextStyle(fontFamily: 'Monospace', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewPage(
                    title: 'Gate_Pass_$storageNo',
                    buildPdf: () => PdfExportService.generateGatePassPdf(
                      gatePassCode: storageNo,
                      warehouseName: _selectedWarehouse,
                      dateStr: _scheduledDate != null
                          ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                          : 'Today',
                      itemCount: _itemCount,
                      laborCount: _workers,
                      tempMode: _selectedStorageMode,
                      truckPlate: _truckPlateCtrl.text,
                      notes: _notesCtrl.text,
                    ),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ReceiveColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, color: ReceiveColors.primary),
            label: Text(
              isAr ? '📄 طباعة / تصدير تصريح الدخول (PDF)' : '📄 Export PDF Gate Pass',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ReceiveColors.primary),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              final resultObj = ReceiveResult(
                storageNo: storageNo,
                bay: bay,
                scheduledAt: _scheduledDate ?? DateTime.now(),
                storageMode: _selectedStorageMode,
                workers: _workers,
                damagePhotosByAdmin: false,
                listingPhotosService: false,
                notes: _notesCtrl.text,
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SmartInventoryStageEN(result: resultObj),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ReceiveColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.analytics_rounded, color: Colors.white),
            label: Text(
              isAr ? 'عرض في المخزون الذكي' : 'View in Smart Inventory',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'العودة للوحة التحكم' : 'Return to Store Dashboard'),
          ),
        ),
      ],
    );
  }

  // ─── Helper Counter Row ──────────────────────────────────────────────────
  Widget _counterRow({
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback onAdd,
    required VoidCallback onMin,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: InventoryColors.textDark)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: InventoryColors.textSub)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ReceiveColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ReceiveColors.cardBorder),
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: onMin),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(icon: const Icon(Icons.add, size: 18), onPressed: onAdd),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String k, String v, {bool isHighlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                k,
                style: const TextStyle(color: InventoryColors.textSub, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isHighlight ? ReceiveColors.primary : InventoryColors.textDark,
                  fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
                  fontSize: isHighlight ? 15 : 13,
                ),
              ),
            ),
          ],
        ),
      );
}
