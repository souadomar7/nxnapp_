import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../services/marketplace_service.dart';
import '../models/invoice.dart';
import '../theme.dart';
import 'payment_page.dart';
import '../services/pdf_export_service.dart';
import 'document_preview_page.dart';
import '../core/utils/validators.dart';

class RequestDeliveryColors {
  static const primary = AppColors.bluePrimary;
  static const background = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textSub = Color(0xFF64748B);
  static const cardBorder = Color(0xFFE2E8F0);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
}

class RequestDeliveryPage extends StatefulWidget {
  const RequestDeliveryPage({super.key});

  @override
  State<RequestDeliveryPage> createState() => _RequestDeliveryPageState();
}

class _RequestDeliveryPageState extends State<RequestDeliveryPage> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final _formKey = GlobalKey<FormState>();

  // Stepper State: 0: Hub & Courier, 1: Recipient & Address, 2: Waybill & Confirmation
  int _currentStep = 0;

  // Controllers
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Selection state
  String _dispatchWarehouse = 'Dubai Central Warehouse';
  String _courierCompany = 'NXN Direct Logistics';
  String _deliveryType = 'Standard (2-3 Days)';
  bool _isInternational = false;

  String? _localCity = 'Dubai';
  String? _country = 'Saudi Arabia';
  String? _internationalCity = 'Riyadh';

  bool _isLoading = false;
  Map<String, dynamic>? _generatedWaybill;

  final List<String> _uaeEmirates = const [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  final Map<String, List<String>> _citiesByCountry = const {
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Dammam', 'Khobar'],
    'Qatar': ['Doha', 'Al Rayyan', 'Al Wakrah'],
    'Bahrain': ['Manama', 'Riffa'],
    'Oman': ['Muscat', 'Salalah', 'Sohar'],
    'Kuwait': ['Kuwait City', 'Hawalli', 'Salmiya'],
    'UK': ['London', 'Manchester', 'Birmingham'],
    'USA': ['New York', 'Los Angeles', 'Chicago'],
  };

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final hasSub = await _marketplaceService.hasActiveSubscription();
    if (!hasSub && mounted) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'يتطلب اشتراك مساحة تخزين نشطة' : 'Active Storage Lease Required',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            isAr
                ? 'يجب أن يكون لديك اشتراك نشط في مساحات التخزين (أرفف مستأجرة) لطلب شحن وتسليم البضائع للعملاء.\n\nيرجى استئجار مساحة أولاً من صفحة استئجار المساحات.'
                : 'You must have an active leased shelf space subscription to request outbound delivery orders.\n\nPlease lease shelf space first from the Space Rental page.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(isAr ? 'موافق' : 'OK', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _calculateFee() {
    double base = 25.0;
    if (_courierCompany.contains('EMX')) base = 35.0;
    if (_courierCompany.contains('Aramex')) base = 60.0;
    if (_deliveryType.contains('Express') || _deliveryType.contains('Same Day')) base += 20.0;
    if (_isInternational) base += 45.0;
    return base;
  }

  Future<void> _submitOutboundDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (!_isInternational && _localCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى اختيار الإمارة' : 'Please select UAE Emirate')),
      );
      return;
    }

    if (_isInternational && (_country == null || _internationalCity == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى اختيار الدولة والمدينة' : 'Please select country and city')),
      );
      return;
    }

    final destinationStr = !_isInternational
        ? '$_localCity, UAE - ${_addressCtrl.text.trim()}'
        : '$_internationalCity, $_country - ${_addressCtrl.text.trim()}';

    setState(() => _isLoading = true);

    final fee = _calculateFee();

    final result = await _marketplaceService.createOutboundDeliveryOrder(
      dispatchWarehouse: _dispatchWarehouse,
      courierCompany: _courierCompany,
      deliverySpeed: _deliveryType,
      recipientName: _recipientNameCtrl.text.trim(),
      recipientPhone: _recipientPhoneCtrl.text.trim(),
      destinationAddress: destinationStr,
      deliveryFee: fee,
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _generatedWaybill = result;
      _currentStep = 2; // Advance to Waybill confirmation step
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade800,
        content: Text(
          isAr
              ? 'تم إنشاء طلب الشحن وإخطار شركاء اللوجستيات ومسئول النظام بنجاح! 🚚'
              : 'Outbound delivery created & Admin notified successfully! 🚚',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: RequestDeliveryColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── 1. Sliver Header ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: RequestDeliveryColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.of(context).pop();
                }
              },
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
                              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'طلب شحن وتوصيل بضائع' : 'Outbound Delivery Request',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr ? 'تجهيز الشحنات من المستودع وتأكيد البوليصة' : 'Dispatch items from warehouse with tracking waybill',
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
                  _stepIndicator(0, isAr ? 'الشحن' : 'Courier', isAr),
                  _stepLine(0),
                  _stepIndicator(1, isAr ? 'المستلم' : 'Recipient', isAr),
                  _stepLine(1),
                  _stepIndicator(2, isAr ? 'البوليصة' : 'Waybill', isAr),
                ],
              ),
            ),
          ),

          // ─── 3. Dynamic Step Content ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Form(
                key: _formKey,
                child: _buildCurrentStepContent(isAr),
              ),
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
      textColor = RequestDeliveryColors.textDark;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrent
                ? RequestDeliveryColors.primary
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
        return _buildStep1CourierAndOptions(isAr);
      case 1:
        return _buildStep2RecipientAndAddress(isAr);
      case 2:
        return _buildStep3WaybillConfirmation(isAr);
      default:
        return const SizedBox();
    }
  }

  // ─── Step 1: Courier Choice & Speed ──────────────────────────────────────
  Widget _buildStep1CourierAndOptions(bool isAr) {
    final warehouses = [
      {'id': 'Dubai Central Warehouse', 'name': isAr ? 'مستودع دبي المركزي' : 'Dubai Central Warehouse'},
      {'id': 'Abu Dhabi Central Hub', 'name': isAr ? 'مستودع أبوظبي المركزي' : 'Abu Dhabi Central Hub'},
      {'id': 'Sharjah Regional Hub', 'name': isAr ? 'مستودع الشارقة الإقليمي' : 'Sharjah Regional Hub'},
      {'id': 'Al Ain Fulfillment Center', 'name': isAr ? 'مركز تجميع العين' : 'Al Ain Fulfillment Center'},
    ];

    final couriers = [
      {
        'title': isAr ? 'NXN اللوجستية المباشرة' : 'NXN Direct Logistics',
        'sub': isAr ? 'شحن مباشر وسريع داخل الإمارات' : 'Direct fulfillment & fleet delivery in UAE',
        'price': 'AED 25.00',
        'icon': Icons.local_shipping_rounded,
      },
      {
        'title': isAr ? 'بريد الإمارات (EMX Express)' : 'EMX Express Courier',
        'sub': isAr ? 'تغظية شاملة لكافة الإمارات' : 'Comprehensive nationwide postal network',
        'price': 'AED 35.00',
        'icon': Icons.markunread_mailbox_rounded,
      },
      {
        'title': isAr ? 'أرامكس (Aramex Regional)' : 'Aramex GCC & Global',
        'sub': isAr ? 'شحن إقليمي ودولي لدول الخليج' : 'Regional GCC & global express freight',
        'price': 'AED 60.00',
        'icon': Icons.flight_takeoff_rounded,
      },
    ];

    final speeds = [
      isAr ? 'عادي (2-3 أيام)' : 'Standard (2-3 Days)',
      isAr ? 'سريع (نفس اليوم)' : 'Express (Same Day)',
      isAr ? 'اقتصادي (5-7 أيام)' : 'Economy (5-7 Days)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الخطوة 1: اختر مستودع التجميع وشركة الشحن' : 'Step 1: Select Dispatch Hub & Courier Partner',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: RequestDeliveryColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'حدد مستودع انطلاق الشحنة وشريك اللوجستيات المناسب' : 'Choose source warehouse and logistics partner for order delivery',
          style: const TextStyle(fontSize: 12, color: RequestDeliveryColors.textSub),
        ),
        const SizedBox(height: 20),

        // Dispatch Warehouse
        Text(isAr ? 'مستودع انطلاق الشحنة' : 'Source Dispatch Warehouse', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _dispatchWarehouse,
          decoration: _inputDeco(),
          dropdownColor: Colors.white,
          items: warehouses.map((w) => DropdownMenuItem(
            value: w['id'] as String,
            child: Text(
              w['name'] as String,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            ),
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _dispatchWarehouse = v);
            }
          },
        ),

        const SizedBox(height: 20),

        // Courier Partner Selection
        Text(isAr ? 'شركة الشحن واللوجستيات' : 'Logistics & Courier Partner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...couriers.map((c) {
          final title = c['title'] as String;
          final selected = _courierCompany == title;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _courierCompany = title),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? RequestDeliveryColors.primary : RequestDeliveryColors.cardBorder, width: selected ? 2 : 1),
                  boxShadow: [
                    if (selected) BoxShadow(color: RequestDeliveryColors.primary.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(c['icon'] as IconData, color: selected ? RequestDeliveryColors.primary : Colors.grey, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: selected ? RequestDeliveryColors.primary : RequestDeliveryColors.textDark)),
                          Text(c['sub'] as String, style: const TextStyle(fontSize: 11, color: RequestDeliveryColors.textSub)),
                        ],
                      ),
                    ),
                    Text(
                      c['price'] as String,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: selected ? RequestDeliveryColors.primary : RequestDeliveryColors.textDark),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        // Delivery Speed Chips
        Text(isAr ? 'سرعة وأولوية التوصيل' : 'Delivery Speed & Priority', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: speeds.map((s) {
              final selected = _deliveryType == s;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: selected,
                  selectedColor: RequestDeliveryColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: selected ? Colors.white : RequestDeliveryColors.textDark),
                  onSelected: (_) => setState(() => _deliveryType = s),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 30),

        // Next Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestDeliveryColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAr ? 'المتابعة لإدخال بيانات المستلم' : 'Continue to Recipient Details',
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

  // ─── Step 2: Recipient Details & Destination ─────────────────────────────
  Widget _buildStep2RecipientAndAddress(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الخطوة 2: بيانات المستلم وعنوان التوصيل' : 'Step 2: Recipient Information & Delivery Address',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: RequestDeliveryColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          isAr ? 'أدخل اسم المستلم، ورقم الهاتف، وعنوان التسليم التفصيلي' : 'Enter recipient name, contact number, and full destination address',
          style: const TextStyle(fontSize: 12, color: RequestDeliveryColors.textSub),
        ),
        const SizedBox(height: 20),

        // Delivery Mode (Domestic vs International)
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isInternational = false),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: !_isInternational ? RequestDeliveryColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: !_isInternational ? RequestDeliveryColors.primary : RequestDeliveryColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded, size: 18, color: !_isInternational ? Colors.white : Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isAr ? 'محلي (الإمارات)' : 'Domestic (UAE)',
                          style: TextStyle(
                            color: !_isInternational ? Colors.white : RequestDeliveryColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isInternational = true),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _isInternational ? RequestDeliveryColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _isInternational ? RequestDeliveryColors.primary : RequestDeliveryColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public_rounded, size: 18, color: _isInternational ? Colors.white : Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isAr ? 'دولي (الخليج)' : 'International (GCC)',
                          style: TextStyle(
                            color: _isInternational ? Colors.white : RequestDeliveryColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Address Selectors
        if (!_isInternational) ...[
          Text(isAr ? 'الإمارة *' : 'UAE Emirate *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _localCity,
            decoration: _inputDeco(),
            dropdownColor: Colors.white,
            items: _uaeEmirates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _localCity = v),
          ),
        ] else ...[
          Text(isAr ? 'الدولة *' : 'Country *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: _inputDeco(),
            dropdownColor: Colors.white,
            items: _citiesByCountry.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() {
              _country = v;
              _internationalCity = _citiesByCountry[v]?.first;
            }),
          ),
          const SizedBox(height: 14),
          Text(isAr ? 'المدينة *' : 'City *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _internationalCity,
            decoration: _inputDeco(),
            dropdownColor: Colors.white,
            items: (_citiesByCountry[_country] ?? []).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _internationalCity = v),
          ),
        ],

        const SizedBox(height: 16),

        // Full Street Address
        Text(isAr ? 'العنوان التفصيلي (الشارع / المبنى / الشقة) *' : 'Full Street Address (Building/Villa/Street) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressCtrl,
          maxLines: 2,
          validator: (v) {
            final err = Validators.deliveryAddress(v);
            if (err != null) return isAr ? 'يرجى إدخال عنوان تفصيلي واضح (المبنى، الشارع)' : err;
            return null;
          },
          decoration: _inputDeco().copyWith(
            hintText: isAr ? 'مثال: برج الياقوت، شارع الشيخ زايد، شقة 1402' : 'e.g. Ruby Tower, Sheikh Zayed Rd, Apt 1402',
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),

        const SizedBox(height: 16),

        // Recipient Name & Phone
        Text(isAr ? 'اسم المستلم الكامل (الاسم الأول واسم العائلة) *' : 'Recipient Full Name *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _recipientNameCtrl,
          validator: (v) {
            final err = Validators.recipientName(v);
            if (err != null) return isAr ? 'يرجى إدخال اسم المستلم الثلاثي أو الثنائي بشكل صحيح' : err;
            return null;
          },
          decoration: _inputDeco().copyWith(
            hintText: isAr ? 'مثال: محمد راشد المنصوري' : 'e.g. Mohammed Rashid Al Mansoori',
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),

        const SizedBox(height: 16),

        Text(isAr ? 'رقم الهاتف المعتمد (واتساب للتوصيل) *' : 'Verified Mobile Number (WhatsApp) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _recipientPhoneCtrl,
          keyboardType: TextInputType.phone,
          validator: (v) {
            final err = Validators.uaePhone(v, allowInternational: _isInternational);
            if (err != null) {
              return isAr
                  ? (_isInternational ? 'صيغة الرقم الدولي غير صحيحة (+رمز الدولة)' : 'رقم الهاتف يجب أن يكون رقم إماراتي صحيح (مثال: 0501234567 أو +971501234567)')
                  : err;
            }
            return null;
          },
          decoration: _inputDeco().copyWith(
            hintText: _isInternational ? '+966 50 123 4567' : '+971 50 123 4567',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),

        const SizedBox(height: 16),

        Text(isAr ? 'ملاحظات وتوجيهات السائق' : 'Driver Delivery Instructions', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: _inputDeco().copyWith(
            hintText: isAr ? 'مثال: الاتصال قبل الوصول بـ 15 دقيقة...' : 'e.g. Call 15 mins before arrival...',
            prefixIcon: const Icon(Icons.note_alt_outlined),
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
                onPressed: _isLoading ? null : _submitOutboundDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RequestDeliveryColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isAr ? 'تأكيد وإصدار بوليصة الشحن' : 'Submit & Generate Waybill',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 3: Courier Waybill & Confirmation ──────────────────────────────
  Widget _buildStep3WaybillConfirmation(bool isAr) {
    final waybillData = _generatedWaybill ?? {};
    final waybillNo = waybillData['waybill'] ?? 'NXN-991823';
    final fee = (waybillData['delivery_fee'] as num?)?.toDouble() ?? 25.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Banner
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
                      isAr ? 'تم إرسال طلب الشحن وإخطار المستودع بنجاح!' : 'Outbound Request Created & Admin Notified!',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? 'تم إخطار فريق التجهيز وشركة الشحن لبدء تجهيز الطلب.' : 'Fulfillment team and courier partner alerted for pickup.',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Waybill Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: RequestDeliveryColors.primary.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: RequestDeliveryColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'بوليصة تتبع الشحنة' : 'COURIER WAYBILL TICKET',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RequestDeliveryColors.primary, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        waybillNo,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: RequestDeliveryColors.textDark),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blueGlow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 36, color: RequestDeliveryColors.primary),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              _infoRow(isAr ? 'مستودع الانطلاق' : 'Source Warehouse', _dispatchWarehouse),
              _infoRow(isAr ? 'شركة الشحن' : 'Courier Partner', _courierCompany),
              _infoRow(isAr ? 'سرعة التوصيل' : 'Delivery Speed', _deliveryType),
              _infoRow(isAr ? 'اسم المستلم' : 'Recipient Name', _recipientNameCtrl.text.trim(), isHighlight: true),
              _infoRow(isAr ? 'رقم التلفون' : 'Contact Phone', _recipientPhoneCtrl.text.trim()),
              _infoRow(isAr ? 'وجهة التسليم' : 'Destination', waybillData['destination'] ?? ''),
              _infoRow(isAr ? 'رسوم الشحن' : 'Delivery Fee', 'AED ${fee.toStringAsFixed(2)}', isHighlight: true),

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
                    const Icon(Icons.line_weight_rounded, size: 36, color: RequestDeliveryColors.textDark),
                    const SizedBox(height: 4),
                    Text(
                      '*$waybillNo*',
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
                    title: 'Waybill_$waybillNo',
                    buildPdf: () => PdfExportService.generateWaybillPdf(
                      waybillCode: waybillNo,
                      courierCompany: _courierCompany,
                      deliverySpeed: _deliveryType,
                      recipientName: _recipientNameCtrl.text.trim(),
                      recipientPhone: _recipientPhoneCtrl.text.trim(),
                      destinationAddress: waybillData['destination'] ?? '',
                      deliveryFee: fee,
                      notes: _notesCtrl.text.trim(),
                    ),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: RequestDeliveryColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded, color: RequestDeliveryColors.primary),
            label: Text(
              isAr ? '📄 طباعة / تصدير بوليصة الشحن (PDF)' : '📄 Export PDF Courier Waybill',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: RequestDeliveryColors.primary),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              final invoice = Invoice(
                id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                number: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                warehouseName: 'Delivery Service ($_deliveryType)',
                date: DateTime.now(),
                amount: fee,
                vat: fee * 0.05,
                paid: false,
                type: InvoiceType.delivery,
                metaData: {
                  'customerName': _recipientNameCtrl.text,
                  'customerAddress': waybillData['destination'] ?? '',
                  'deliveryMethod': '$_courierCompany - $_deliveryType',
                },
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PaymentsPage(initialInvoice: invoice)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestDeliveryColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.payment_rounded, color: Colors.white),
            label: Text(
              isAr ? 'الانتقال لصفحة دفع رسوم الشحن' : 'Proceed to Shipping Payment',
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

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: RequestDeliveryColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: RequestDeliveryColors.cardBorder),
      ),
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
                style: const TextStyle(color: RequestDeliveryColors.textSub, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isHighlight ? RequestDeliveryColors.primary : RequestDeliveryColors.textDark,
                  fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
                  fontSize: isHighlight ? 15 : 13,
                ),
              ),
            ),
          ],
        ),
      );
}
