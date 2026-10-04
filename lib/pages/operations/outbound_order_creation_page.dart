import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/commercial_model.dart';
import '../../models/marketplace_models.dart';
import '../../models/invoice.dart';
import '../../services/marketplace_service.dart';
import '../checkout_page.dart';

class OutboundOrderCreationPage extends StatefulWidget {
  const OutboundOrderCreationPage({super.key});

  @override
  State<OutboundOrderCreationPage> createState() => _OutboundOrderCreationPageState();
}

class _OutboundOrderCreationPageState extends State<OutboundOrderCreationPage> {
  final _formKey = GlobalKey<FormState>();

  // Consignee Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+971 ');
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedEmirate = 'Dubai';

  final List<String> _emirates = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Ras Al Khaimah',
    'Fujairah',
    'Umm Al Quwain',
    'Al Ain',
  ];

  // Delivery Method Selection
  DeliveryMethod _selectedDeliveryMethod = DeliveryMethod.standardNextDay;

  // Inventory items available for picking
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<SmeProduct> _availableProducts = [];
  bool _isLoadingProducts = true;

  // Selected items to pick: map of productId -> quantity
  final Map<String, int> _pickedQuantities = {};
  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadMerchantInventory();
  }

  Future<void> _loadMerchantInventory() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _marketplaceService.getSellerProducts();
      setState(() {
        _availableProducts = products.isNotEmpty
            ? products
            : [
                SmeProduct(
                  id: 'P-101',
                  sellerId: 'current-user',
                  name: 'Cold Brew Coffee 250ml',
                  nameAr: 'قهوة كولد برو 250 مل',
                  description: 'Premium organic cold brew bottles',
                  price: 18.0,
                  quantity: 45,
                  createdAt: DateTime.now(),
                ),
                SmeProduct(
                  id: 'P-102',
                  sellerId: 'current-user',
                  name: 'Organic Sidr Honey 500g',
                  nameAr: 'عسل سدر إماراتي عضوي 500 جم',
                  description: '100% Pure Emirati Honey jar',
                  price: 120.0,
                  quantity: 28,
                  createdAt: DateTime.now(),
                ),
                SmeProduct(
                  id: 'P-103',
                  sellerId: 'current-user',
                  name: 'Artisan Ceramic Mug',
                  nameAr: 'كوب سيراميك يدوي الصنع',
                  description: 'Handmade local craft pottery',
                  price: 45.0,
                  quantity: 16,
                  createdAt: DateTime.now(),
                ),
              ];
        _isLoadingProducts = false;
      });
    } catch (_) {
      setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalItemsPrice {
    double sum = 0.0;
    for (final p in _availableProducts) {
      final q = _pickedQuantities[p.id] ?? 0;
      sum += (p.price * q);
    }
    return sum;
  }

  int get _totalItemsCount {
    int count = 0;
    for (final q in _pickedQuantities.values) {
      count += q;
    }
    return count;
  }

  double get _deliveryFee => _selectedDeliveryMethod.fee;
  double get _platformCommission => _totalItemsPrice * CommercialModel.platformCommissionRate;
  double get _subtotalFulfillment => _deliveryFee + _platformCommission;
  double get _vat => _subtotalFulfillment * CommercialModel.uaeVatRate;
  double get _totalPayable => _subtotalFulfillment + _vat;

  Future<void> _submitOutboundOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalItemsCount == 0) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            isAr
                ? '⚠️ يرجى اختيار صنف وكمية واحدة على الأقل لطلب الشحن والتجهيز.'
                : '⚠️ Please select at least one item and quantity to be picked from your shelves.',
          ),
        ),
      );
      return;
    }

    setState(() => _isCreatingOrder = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isCreatingOrder = false);

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final orderRef = 'NXN-OUT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Show Dialog with Picking Confirmation and Instant Dispatch Slip
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF10AC84), size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'تم إرسال أمر التجهيز والشحن! 🚀' : 'Outbound Fulfillment Order Placed! 🚀',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr
                    ? 'سيقوم فريق مستودع NXN بسحب وتغليف الأصناف المحددة وتسليمها لمندوب التوصيل فوراً.'
                    : 'NXN warehouse team is picking your items from shelf inventory for courier dispatch.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _infoRow(isAr ? 'رقم الإرسالية:' : 'Dispatch Ref:', orderRef),
                    _infoRow(isAr ? 'المرسل إليه:' : 'Consignee:', _nameCtrl.text.trim()),
                    _infoRow(isAr ? 'رقم الهاتف:' : 'Phone:', _phoneCtrl.text.trim()),
                    _infoRow(isAr ? 'وجهة التسليم:' : 'Destination:', '$_selectedEmirate, ${_addressCtrl.text.trim()}'),
                    _infoRow(isAr ? 'طريقة التوصيل:' : 'Service Level:', _selectedDeliveryMethod.label(isAr)),
                    _infoRow(isAr ? 'إجمالي القطع المسحوبة:' : 'Total Units to Pick:', '$_totalItemsCount items'),
                    const Divider(height: 16),
                    _infoRow(
                      isAr ? 'رسوم التجهيز والتوصيل:' : 'Fulfillment & Delivery:',
                      'AED ${_totalPayable.toStringAsFixed(2)}',
                      isBold: true,
                      color: AppColors.bluePrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(isAr ? 'إغلاق' : 'Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final invoice = Invoice(
                id: orderRef,
                number: orderRef,
                warehouseName: 'NXN Outbound Fulfillment Hub',
                warehouseNameAr: 'مركز NXN للتجهيز والتوزيع',
                date: DateTime.now(),
                amount: _subtotalFulfillment,
                vat: _vat,
                type: InvoiceType.delivery,
                metaData: {
                  'order_reference': orderRef,
                  'items_count': _totalItemsCount,
                  'consignee': _nameCtrl.text.trim(),
                  'delivery_method': _selectedDeliveryMethod.code,
                },
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckoutPage(invoice: invoice)),
              );
            },
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: Text(isAr ? 'دفع الرسوم عبر Fintx' : 'Pay via Fintx Gateway'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
          isAr ? 'إنشاء طلب شحن وتوزيع خارجي (Outbound)' : 'Create Outbound Fulfillment Order',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.outbox_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'تجهيز وتوصيل طلبات متجرك' : 'Home Seller Outbound Dispatch',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr
                                      ? 'حدد بيانات العميل، واختر المنتجات المطلوب سحبها من الرف مع وسيلة التوصيل.'
                                      : 'Enter customer consignee details, pick shelf items, and choose delivery tier.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Step 1: Consignee Details Check
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_pin_circle_outlined, color: AppColors.bluePrimary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isAr ? '1. بيانات المستلم (Consignee Details)' : '1. Consignee Details Check',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? 'اسم المستلم الكامل *' : 'Customer / Consignee Full Name *',
                              hintText: isAr ? 'مثال: محمد الشامسي' : 'e.g. Mohammed Al Nuaimi',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: isAr ? 'رقم هاتف المستلم للتوصيل *' : 'Consignee Mobile Number *',
                              hintText: '+971 50 123 4567',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return isAr ? 'مطلوب' : 'Required';
                              if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 8) {
                                return isAr ? 'يرجى إدخال رقم هاتف إماراتي صحيح' : 'Valid UAE phone required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedEmirate,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الإمارة / المدينة *' : 'Emirate / City *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.location_city_outlined),
                            ),
                            items: _emirates
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedEmirate = v ?? _selectedEmirate),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? 'عنوان التوصيل التفصيلي (الفيلا/البناية، الشارع) *' : 'Full Street Address (Villa/Apt, Street) *',
                              hintText: isAr ? 'مثال: دبي، ند الشبا، فيلا 24' : 'e.g. Nad Al Sheba 2, Villa 24',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.map_outlined),
                            ),
                            maxLines: 2,
                            validator: (v) => v == null || v.trim().isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? 'ملاحظات التسليم (اختياري)' : 'Delivery Notes (Optional)',
                              hintText: isAr ? 'مثال: يرجى الاتصال قبل الوصول' : 'e.g. Ring bell, call upon arrival',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.note_alt_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Step 2: Items to be Picked from Stored Shelf
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
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
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF3E8FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.shelves, color: Color(0xFF9333EA), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        isAr ? '2. اختيار الأصناف المسحوبة' : '2. Items to be Picked from Shelf',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_totalItemsCount ${isAr ? 'قطع' : 'Units'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9333EA)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._availableProducts.map((p) {
                            final currentPicked = _pickedQuantities[p.id] ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: currentPicked > 0 ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: currentPicked > 0 ? const Color(0xFFC084FC) : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAr ? p.getLocalizedName(true) : p.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'AED ${p.price.toStringAsFixed(2)} • ${isAr ? 'المتوفر على الرف:' : 'In Shelf Stock:'} ${p.quantity}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                        onPressed: currentPicked > 0
                                            ? () => setState(() {
                                                  _pickedQuantities[p.id] = currentPicked - 1;
                                                })
                                            : null,
                                      ),
                                      Text(
                                        '$currentPicked',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: currentPicked > 0 ? const Color(0xFF9333EA) : Colors.grey,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, color: Color(0xFF9333EA)),
                                        onPressed: currentPicked < p.quantity
                                            ? () => setState(() {
                                                  _pickedQuantities[p.id] = currentPicked + 1;
                                                })
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Step 3: Delivery Service Selection
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF059669), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isAr ? '3. وسيلة ومستوى التوصيل' : '3. Delivery Method Selection',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ...DeliveryMethod.values.map((method) {
                            final isSelected = _selectedDeliveryMethod == method;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDeliveryMethod = method),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF10AC84) : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: isSelected ? const Color(0xFF10AC84) : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        method.label(isAr),
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13,
                                          color: isSelected ? const Color(0xFF065F46) : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      method.fee == 0 ? (isAr ? 'مجاني' : 'FREE') : 'AED ${method.fee.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected ? const Color(0xFF065F46) : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Commercial & Fee Breakdown Summary
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bluePrimary.withValues(alpha: 0.05),
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
                              Text(
                                isAr ? 'ملخص التكلفة والرسوم' : 'Commercial Fee Summary',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_outlined, color: Color(0xFF10AC84), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Fintx Gateway',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _summaryLine(
                            isAr ? 'قيمة المنتجات المسحوبة:' : 'Total Value of Items:',
                            'AED ${_totalItemsPrice.toStringAsFixed(2)}',
                          ),
                          _summaryLine(
                            isAr ? 'رسوم التوصيل المختار:' : 'Delivery Service Fee:',
                            'AED ${_deliveryFee.toStringAsFixed(2)}',
                          ),
                          _summaryLine(
                            isAr ? 'عمولة منصة NXN (5%):' : 'NXN Platform Commission (5%):',
                            'AED ${_platformCommission.toStringAsFixed(2)}',
                          ),
                          _summaryLine(
                            isAr ? 'ضريبة القيمة المضافة (5% VAT):' : 'UAE VAT (5%):',
                            'AED ${_vat.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr ? 'إجمالي رسوم التجهيز والشحن:' : 'Total Fulfillment Cost:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'AED ${_totalPayable.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppColors.bluePrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: _isCreatingOrder ? null : _submitOutboundOrder,
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      label: _isCreatingOrder
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isAr ? 'تأكيد وإرسال أمر الشحن والتوزيع 🚀' : 'Confirm & Dispatch Outbound Order 🚀',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
