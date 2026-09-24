import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../services/marketplace_service.dart';

class CreateShipmentPage extends StatefulWidget {
  const CreateShipmentPage({super.key});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  // Shipment type — Drop-off is default
  bool _isDropOff = true;
  
  // Common fields
  String? _selectedWarehouseId;
  List<Map<String, dynamic>> _warehouses = [];
  final _itemCountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingWarehouses = true;

  // Pick-up only fields
  final _pickupLocationNameCtrl = TextEditingController();
  final _pickupAddressCtrl = TextEditingController();
  String _goodsType = 'General Merchandise';
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();

  final List<String> _goodsTypes = [
    'General Merchandise',
    'Electronics',
    'Food & Beverage',
    'Fashion & Apparel',
    'Furniture & Home',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final data = await _supabase.from('warehouses').select();
      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(data);
        if (_warehouses.isNotEmpty) _selectedWarehouseId = _warehouses.first['id'];
        _isLoadingWarehouses = false;
      });
    } catch (e) {
      setState(() => _isLoadingWarehouses = false);
    }
  }

  @override
  void dispose() {
    _itemCountCtrl.dispose();
    _notesCtrl.dispose();
    _pickupLocationNameCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWarehouseId == null) return;
    setState(() => _isLoading = true);
    try {
      final service = MarketplaceService();
      // Build extra notes with pick-up info if needed
      String notes = _notesCtrl.text.trim();
      if (!_isDropOff) {
        notes = 'PICKUP REQUEST\n'
            'Location: ${_pickupLocationNameCtrl.text}\n'
            'Address: ${_pickupAddressCtrl.text}\n'
            'Goods Type: $_goodsType\n'
            'Contact: ${_contactNameCtrl.text} (${_contactPhoneCtrl.text})\n'
            'Notes: $notes';
      }
      final gatePassCode = 'GP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await service.createInboundRequest(
        warehouseId: _selectedWarehouseId!,
        expectedDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
        itemCount: int.tryParse(_itemCountCtrl.text) ?? 1,
        notes: notes,
        shipmentType: _isDropOff ? 'drop_off' : 'pick_up',
      );

      if (mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        final selectedWh = _warehouses.firstWhere(
          (w) => w['id'] == _selectedWarehouseId,
          orElse: () => {'name': 'NXN Smart Hub'},
        );
        final whName = selectedWh['name'] ?? selectedWh['name_ar'] ?? 'NXN Logistics Hub';

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10AC84), size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'تم إنشاء تصريح الدخول! 🎫' : 'Dock Gate-Pass Generated! 🎫',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr
                      ? 'تم تسجيل طلب الشحن وتوليد تصريح الدخول الذكي للبوابة. أظهر هذا الرمز عند وصول الشاحنة للمستودع.'
                      : 'Shipment registered successfully. Present this digital gate-pass at the warehouse dock gate for instant check-in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: QrImageView(
                          data: 'NXN-GATEPASS:$gatePassCode|WH:$_selectedWarehouseId',
                          version: QrVersions.auto,
                          size: 140.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.bluePrimary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '#$gatePassCode',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AppColors.bluePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'المستودع' : 'Facility', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Expanded(
                            child: Text(
                              whName,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'نوع الشحن' : 'Type', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(
                            _isDropOff ? (isAr ? 'تسليم مباشر (Drop-off)' : 'Drop-off') : (isAr ? 'استلام NXN (Pick-up)' : 'Pick-up'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10AC84)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.pop(context);
                },
                child: Text(isAr ? 'تم والمتابعة' : 'Done & Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? 'إرسال بضائع للمستودع' : 'Send Goods to Warehouse',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingWarehouses
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Drop-off / Pick-up Toggle ──────────────────────
                    Text(
                      isAr ? 'طريقة الشحن' : 'Shipment Method',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isDropOff = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isDropOff ? AppColors.bluePrimary.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isDropOff ? AppColors.bluePrimary : Colors.grey.shade300,
                                  width: _isDropOff ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.warehouse_rounded,
                                    size: 32,
                                    color: _isDropOff ? AppColors.bluePrimary : Colors.grey.shade500),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr ? 'Drop-off' : 'Drop-off',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _isDropOff ? AppColors.bluePrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr ? 'أحضر بضاعتك بنفسك' : 'Bring goods yourself',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_isDropOff) ...
                                    [const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.bluePrimary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isAr ? 'افتراضي' : 'Default',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isDropOff = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: !_isDropOff ? const Color(0xFFFF9F43).withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !_isDropOff ? const Color(0xFFFF9F43) : Colors.grey.shade300,
                                  width: !_isDropOff ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.local_shipping_rounded,
                                    size: 32,
                                    color: !_isDropOff ? const Color(0xFFFF9F43) : Colors.grey.shade500),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr ? 'Pick-up' : 'Pick-up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: !_isDropOff ? const Color(0xFFFF9F43) : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr ? 'استلام من موقعك' : 'We collect from you',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_isDropOff ? AppColors.bluePrimary : const Color(0xFFFF9F43)).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isDropOff
                          ? (isAr ? '🏭 ستحضر بضاعتك إلى المستودع بنفسك.' : '🏭 You will bring your goods to the warehouse yourself.')
                          : (isAr ? '🚛 سيقوم فريقنا باستلام بضاعتك من موقعك المحدد.' : '🚛 Our team will pick up your goods from your specified location.'),
                        style: TextStyle(
                          color: _isDropOff ? AppColors.bluePrimary : const Color(0xFFE67E22),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Warehouse Selection ────────────────────────────
                    Text(isAr ? 'المستودع' : 'Warehouse', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedWarehouseId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.warehouse_outlined),
                      ),
                      items: _warehouses.map((w) => DropdownMenuItem(
                        value: w['id'] as String,
                        child: Text(isAr ? (w['name_ar'] ?? w['name']) : w['name']),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedWarehouseId = v),
                      validator: (v) => v == null ? (isAr ? 'يرجى اختيار مستودع' : 'Please select a warehouse') : null,
                    ),

                    const SizedBox(height: 16),

                    // ── Pick-up Extra Fields (animated) ─────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isDropOff ? const SizedBox.shrink() : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFCC80)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'تفاصيل موقع الاستلام' : 'Pick-up Location Details',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _pickupLocationNameCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'اسم الموقع *' : 'Location Name *',
                                    hintText: isAr ? 'مثال: مستودعي في القوز' : 'e.g. My Warehouse in Al Quoz',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  validator: (v) => !_isDropOff && (v == null || v.isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _pickupAddressCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'عنوان الاستلام الكامل *' : 'Full Pickup Address *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.map_outlined),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  maxLines: 2,
                                  validator: (v) => !_isDropOff && (v == null || v.isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _goodsType,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'نوع البضاعة' : 'Type of Goods',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  items: _goodsTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: (v) => setState(() => _goodsType = v ?? _goodsType),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _contactNameCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'اسم جهة الاتصال *' : 'Contact Person Name *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.person_outline),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  validator: (v) => !_isDropOff && (v == null || v.isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _contactPhoneCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'رقم هاتف الاتصال *' : 'Contact Phone *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => !_isDropOff && (v == null || v.isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // ── Common Fields ──────────────────────────────────
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined, color: AppColors.bluePrimary),
                      title: Text(isAr ? 'التاريخ المتوقع' : 'Expected Date'),
                      subtitle: Text(
                        _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : (isAr ? 'اختر تاريخاً' : 'Select a date'),
                      ),
                      onTap: _selectDate,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                    const Divider(),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _itemCountCtrl,
                      decoration: InputDecoration(
                        labelText: isAr ? 'عدد القطع / الطرود *' : 'Number of Items / Parcels *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.inventory_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return isAr ? 'مطلوب' : 'Required';
                        if (int.tryParse(v) == null) return isAr ? 'رقم غير صحيح' : 'Invalid number';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(
                        labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.notes_outlined),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isAr ? 'إرسال الطلب' : 'Submit Request',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
