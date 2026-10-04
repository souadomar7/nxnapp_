import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../services/marketplace_service.dart';
import '../models/invoice.dart';
import '../core/utils/validators.dart';
import 'booking_page.dart';

class CreateShipmentPage extends StatefulWidget {
  final bool initialIsDropOff;
  final int? initialItemCount;
  final String? initialWarehouseId;
  final String? initialGoodsType;
  final String? initialPickupLocation;
  final String? initialPickupAddress;

  const CreateShipmentPage({
    super.key,
    this.initialIsDropOff = true,
    this.initialItemCount,
    this.initialWarehouseId,
    this.initialGoodsType,
    this.initialPickupLocation,
    this.initialPickupAddress,
  });

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  // Shipment type — Drop-off is default
  late bool _isDropOff;
  
  // Common fields
  String? _selectedWarehouseId;
  List<Map<String, dynamic>> _warehouses = [];
  late final TextEditingController _itemCountCtrl;
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLoadingWarehouses = true;
  bool _hasActiveLease = true;

  // Pick-up only fields
  late final TextEditingController _pickupLocationNameCtrl;
  late final TextEditingController _pickupAddressCtrl;
  late String _goodsType;
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

  // UAE Civil Defence / MOIAT Dangerous Goods Compliance
  bool _declaredNonHazardous = false;

  @override
  void initState() {
    super.initState();
    _isDropOff = widget.initialIsDropOff;
    _itemCountCtrl = TextEditingController(text: widget.initialItemCount?.toString() ?? '');
    _pickupLocationNameCtrl = TextEditingController(text: widget.initialPickupLocation ?? '');
    _pickupAddressCtrl = TextEditingController(text: widget.initialPickupAddress ?? '');
    _goodsType = widget.initialGoodsType ?? 'General Merchandise';
    _selectedWarehouseId = widget.initialWarehouseId;
    _loadWarehouses();
    _checkActiveLease();
  }

  Future<void> _checkActiveLease() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      final invoices = await MarketplaceService().getInvoices();
      final hasRental = invoices.any((i) => i.paid && i.type == InvoiceType.rental);
      if (mounted) setState(() => _hasActiveLease = hasRental);
      return;
    }
    try {
      final res = await _supabase
          .from('sme_subscriptions')
          .select('id')
          .eq('seller_id', user.id)
          .eq('is_active', true)
          .limit(1);
      final hasActive = (res as List).isNotEmpty;
      if (mounted) setState(() => _hasActiveLease = hasActive);
    } catch (_) {}
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoadingWarehouses = true);
    final List<Map<String, dynamic>> list = [];
    final user = _supabase.auth.currentUser;

    // 1. Prioritize active leased warehouses for the logged-in merchant
    if (user != null) {
      try {
        final subs = await _supabase
            .from('sme_subscriptions')
            .select('warehouse_id, shelves_count, warehouses(id, name, name_ar, emirate, address)')
            .eq('seller_id', user.id)
            .eq('is_active', true);

        for (var sub in (subs as List)) {
          final wh = sub['warehouses'] as Map<String, dynamic>?;
          final whId = wh?['id']?.toString() ?? sub['warehouse_id']?.toString();
          if (whId != null) {
            final shelves = (sub['shelves_count'] as num?)?.toInt() ?? 1;
            final existingIdx = list.indexWhere((w) => w['id'] == whId);
            if (existingIdx != -1) {
              list[existingIdx]['shelves_count'] = (list[existingIdx]['shelves_count'] as int) + shelves;
            } else {
              list.add({
                'id': whId,
                'name': wh?['name'] ?? 'Warehouse Hub ($whId)',
                'name_ar': wh?['name_ar'] ?? wh?['name'] ?? 'مستودع ($whId)',
                'emirate': wh?['emirate'] ?? 'Dubai',
                'is_active_lease': true,
                'shelves_count': shelves,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading active user leases: $e');
      }
    }

    // 2. Query all general warehouses from Supabase
    try {
      final data = await _supabase.from('warehouses').select();
      for (var w in (data as List)) {
        if (!list.any((item) => item['id'] == w['id'])) {
          list.add({
            'id': w['id'].toString(),
            'name': w['name'] ?? 'Warehouse',
            'name_ar': w['name_ar'] ?? w['name'] ?? 'مستودع',
            'emirate': w['emirate'] ?? 'Dubai',
            'is_active_lease': false,
            'shelves_count': 0,
          });
        }
      }
    } catch (e) {
      debugPrint('Error querying general warehouses: $e');
    }

    // 3. Fallback standard UAE Hubs if offline or empty so dropdown is NEVER blank
    if (list.isEmpty) {
      list.addAll([
        {
          'id': 'dxb',
          'name': 'Dubai Central Warehouse (Al Quoz)',
          'name_ar': 'مستودع دبي المركزي (القوز)',
          'emirate': 'Dubai',
          'is_active_lease': true,
          'shelves_count': 2,
        },
        {
          'id': 'dxb-2',
          'name': 'Dubai South Logistics Hub',
          'name_ar': 'مستودع دبي الجنوب اللوجستي',
          'emirate': 'Dubai',
          'is_active_lease': false,
          'shelves_count': 0,
        },
        {
          'id': 'auh',
          'name': 'Abu Dhabi Central Hub (KIZAD)',
          'name_ar': 'مستودع أبوظبي المركزي (كيزاد)',
          'emirate': 'Abu Dhabi',
          'is_active_lease': false,
          'shelves_count': 0,
        },
        {
          'id': 'shj',
          'name': 'Sharjah Regional Hub (Industrial Area)',
          'name_ar': 'مستودع الشارقة الإقليمي (المنطقة الصناعية)',
          'emirate': 'Sharjah',
          'is_active_lease': false,
          'shelves_count': 0,
        },
        {
          'id': 'aln',
          'name': 'Al Ain Central Hub (Sanaiya)',
          'name_ar': 'مستودع العين المركزي (الصناعية)',
          'emirate': 'Al Ain',
          'is_active_lease': false,
          'shelves_count': 0,
        },
      ]);
    }

    if (mounted) {
      setState(() {
        _warehouses = list;
        // Prioritize active lease if selected id is null or invalid
        if (_selectedWarehouseId == null || !list.any((w) => w['id'] == _selectedWarehouseId)) {
          final firstActive = list.firstWhere((w) => w['is_active_lease'] == true, orElse: () => list.first);
          _selectedWarehouseId = firstActive['id'] as String;
        }
        _isLoadingWarehouses = false;
      });
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (!_declaredNonHazardous) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            isAr
                ? 'يرجى الإقرار بعدم احتواء الشحنة على مواد خطرة وفقاً لاشتراطات الدفاع المدني الإماراتي.'
                : 'Please declare that cargo contains no hazardous/prohibited materials per UAE Civil Defence regulations.',
          ),
        ),
      );
      return;
    }
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
                  isAr ? 'تم تأكيد موعد التوريد! 📦' : 'Inbound Intake Receipt Generated! 📦',
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
                      ? 'تم تسجيل طلب التوريد بنجاح. أظهر رمز الاستجابة السريعة (QR) وبطاقة الهوية في مكتب استقبال NXN لإتمام استلام البضائع.'
                      : 'Inbound shipment registered. Present this digital intake QR code with your Emirates ID at the NXN Office Reception desk.',
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
                          data: 'NXN-INBOUND-ASN:$gatePassCode|WH:$_selectedWarehouseId',
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
                    if (!_hasActiveLease)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  isAr ? 'تنبيه: يلزم حجز مساحة تخزينية أولاً' : 'Active Shelf Lease Required',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'يجب استئجار مساحة رفوف في المستودع قبل إرسال شحنات البضائع.'
                                  : 'You must lease warehouse shelf space before creating inbound drop-off shipments.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BookingPage()),
                              ),
                              icon: const Icon(Icons.shelves, size: 16),
                              label: Text(isAr ? 'احجز مساحة الآن (100 د.إ/شهر)' : 'Lease Shelves Now (AED 100/mo)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),

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
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFFD97706),
                                  content: Text(
                                    isAr
                                        ? '⚠️ خدمة الاستلام من الموقع (Collection) محدودة الأسطول حالياً، يُنصح باختيار التسليم المباشر (Drop-off).'
                                        : '⚠️ Collection fleet is currently limited. We recommend Drop-off for fastest intake.',
                                  ),
                                ),
                              );
                              setState(() => _isDropOff = false);
                            },
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
                                    isAr ? 'استلام من موقعك (محدود)' : 'Collection (Limited)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isAr ? 'أسطول محدود' : 'Limited Fleet',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
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
                          ? (isAr ? '🏭 التسليم المباشر (Drop-off): أحضر بضاعتك للمستودع، ويتم الاستلام فوراً بالعدد وفحص التلف.' : '🏭 Drop-off: Bring your cargo to our warehouse dock for instant count & inspection.')
                          : (isAr ? '⚠️ تنبيه: الاستلام من الموقع يخضع لجدول مواعيد الأسطول المحدود حالياً.' : '⚠️ Note: Collection pickup is subject to limited fleet scheduling.'),
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
                      initialValue: _selectedWarehouseId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.warehouse_outlined, color: AppColors.bluePrimary),
                        hintText: isAr ? 'اختر المستودع' : 'Select warehouse',
                      ),
                      items: _warehouses.map((w) {
                        final isActiveLease = w['is_active_lease'] == true;
                        final name = isAr ? (w['name_ar'] ?? w['name']) : w['name'];
                        final shelves = w['shelves_count'] ?? 0;

                        return DropdownMenuItem<String>(
                          value: w['id'] as String,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.toString(),
                                  style: TextStyle(
                                    fontWeight: isActiveLease ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                    color: isActiveLease ? AppColors.bluePrimary : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActiveLease)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, size: 11, color: Color(0xFF059669)),
                                      const SizedBox(width: 3),
                                      Text(
                                        isAr ? 'مستودعك المؤجر ($shelves رف)' : 'Active Lease ($shelves Shelves)',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
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
                                    hintText: isAr ? 'مثال: مستودع رقم 12، منطقة القوز الصناعية 3' : 'e.g. Warehouse 12, Al Quoz Ind. 3',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.map_outlined),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  maxLines: 2,
                                  validator: (v) {
                                    if (_isDropOff) return null;
                                    final err = Validators.deliveryAddress(v);
                                    if (err != null) return isAr ? 'يرجى إدخال عنوان استلام تفصيلي' : err;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _goodsType,
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
                                    hintText: isAr ? 'مثال: أحمد المنصوري' : 'e.g. Ahmed Al Mansoori',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.person_outline),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  validator: (v) {
                                    if (_isDropOff) return null;
                                    final err = Validators.recipientName(v);
                                    if (err != null) return isAr ? 'يرجى إدخال اسم جهة الاتصال بشكل صحيح' : err;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _contactPhoneCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'رقم هاتف الاتصال المعتمد *' : 'Contact Phone (WhatsApp) *',
                                    hintText: '+971 50 123 4567',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.phone_outlined),
                                    filled: true, fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (_isDropOff) return null;
                                    final err = Validators.uaePhone(v, allowInternational: false);
                                    if (err != null) {
                                      return isAr ? 'رقم الهاتف يجب أن يكون رقم إماراتي صحيح (مثال: +971501234567 أو 0501234567)' : err;
                                    }
                                    return null;
                                  },
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

                    const SizedBox(height: 20),

                    // ── UAE Civil Defence & MOIAT Compliance Card ─────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _declaredNonHazardous
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _declaredNonHazardous
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 20,
                                color: _declaredNonHazardous
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? 'اشتراطات الدفاع المدني ووزارة الصناعة (MOIAT)'
                                      : 'UAE Civil Defence & MOIAT Safety Compliance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _declaredNonHazardous
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline_rounded, size: 18),
                                color: Colors.grey.shade600,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      title: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                          const SizedBox(width: 8),
                                          Text(
                                            isAr ? 'المواد المحظورة' : 'Prohibited Materials',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        isAr
                                            ? 'وفقاً للقوانين الاتحادية بدولة الإمارات، يُحظر تخزين المواد التالية في المستودعات القياسية دون ترخيص خاص:\n\n'
                                              '• السوائل والمواد القابلة للاشتعال (بنزين، كحول صناعي، تنر)\n'
                                              '• أسطوانات الغاز المضغوط والمتفجرات\n'
                                              '• المواد الكيميائية السامة أو المشعة\n'
                                              '• البضائع المقلدة أو منتهية الصلاحية\n'
                                              '• الأدوية التي تتطلب رقابة خاصة دون تصريح MoHaP'
                                            : 'Per UAE Federal Regulations and Civil Defence safety codes, standard warehouse storage strictly prohibits:\n\n'
                                              '• Flammable liquids, solvents, and fuel\n'
                                              '• Compressed gas cylinders and explosives\n'
                                              '• Toxic, hazardous chemicals or radioactive items\n'
                                              '• Counterfeit or expired merchandise\n'
                                              '• Unlicensed pharmaceuticals or controlled substances',
                                        style: const TextStyle(fontSize: 13, height: 1.5),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(isAr ? 'فهمت ذلك' : 'Understood'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => setState(() => _declaredNonHazardous = !_declaredNonHazardous),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _declaredNonHazardous,
                                      activeColor: const Color(0xFF16A34A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) => setState(() => _declaredNonHazardous = val ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isAr
                                          ? 'أقر بأن جميع البضائع الواردة متوافقة مع اشتراطات السلامة وخالية من أي مواد خطرة أو محظورة قانوناً.'
                                          : 'I declare that this cargo strictly complies with UAE safety laws and contains zero hazardous or prohibited materials.',
                                      style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
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
