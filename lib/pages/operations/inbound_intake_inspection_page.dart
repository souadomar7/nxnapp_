import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme.dart';
import '../../models/commercial_model.dart';

class InboundIntakeInspectionPage extends StatefulWidget {
  final String? shipmentId;
  final String? warehouseName;
  final int initialExpectedCount;

  const InboundIntakeInspectionPage({
    super.key,
    this.shipmentId,
    this.warehouseName,
    this.initialExpectedCount = 50,
  });

  @override
  State<InboundIntakeInspectionPage> createState() => _InboundIntakeInspectionPageState();
}

class _InboundIntakeInspectionPageState extends State<InboundIntakeInspectionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _receivedCountCtrl;
  late final TextEditingController _damagedCountCtrl;
  final _damageDescriptionCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<File> _damageImages = [];
  bool _requestPhotographyVas = false;
  int _photographyCount = 5;
  bool _isSubmitting = false;

  late int _expectedCount;

  @override
  void initState() {
    super.initState();
    _expectedCount = widget.initialExpectedCount;
    _receivedCountCtrl = TextEditingController(text: _expectedCount.toString());
    _damagedCountCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _receivedCountCtrl.dispose();
    _damagedCountCtrl.dispose();
    _damageDescriptionCtrl.dispose();
    super.dispose();
  }

  int get _receivedCount => int.tryParse(_receivedCountCtrl.text) ?? 0;
  int get _damagedCount => int.tryParse(_damagedCountCtrl.text) ?? 0;
  int get _soundCount => (_receivedCount - _damagedCount).clamp(0, 99999);

  Future<void> _pickDamageImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        setState(() {
          _damageImages.add(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr ? 'التقاط صورة توثيق التلفيات' : 'Capture Damage Evidence Photo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.bluePrimary,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: Text(isAr ? 'الكاميرا (تصوير فوري)' : 'Camera (Instant Photo)'),
                subtitle: Text(isAr ? 'تصوير البضاعة المتضررة على رصيف الاستلام' : 'Snap damaged boxes on intake dock'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDamageImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF10AC84),
                  child: Icon(Icons.photo_library_rounded, color: Colors.white),
                ),
                title: Text(isAr ? 'معرض الصور' : 'Photo Gallery'),
                subtitle: Text(isAr ? 'اختيار صور من الجهاز' : 'Select from library'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDamageImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitIntake() async {
    if (!_formKey.currentState!.validate()) return;
    if (_damagedCount > 0 && _damageImages.isEmpty) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            isAr
                ? '⚠️ يرجى التقاط صورة واحدة على الأقل لتوثيق الطرود المتضررة قبل الإتمام.'
                : '⚠️ Please capture at least one photo documenting the damaged items.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final recordId = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10AC84), size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              isAr ? 'تم اعتماد محضر الاستلام والفحص!' : 'Intake Inspection Certified!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'تم استلام وتوثيق الشحنة وتحديث رصيد الأرفف المتاحة في المستودع بنجاح.'
                  : 'Cargo intake verified by count and stored safely on assigned shelves.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _summaryRow(isAr ? 'رقم الإيصال:' : 'Intake Ref:', recordId),
                  _summaryRow(isAr ? 'القطع السليمة المعتمدة:' : 'Sound Stock Accepted:', '$_soundCount units'),
                  if (_damagedCount > 0)
                    _summaryRow(
                      isAr ? 'المعزول في الحجر (تالف):' : 'Quarantined (Damaged):',
                      '$_damagedCount units',
                      textColor: Colors.red.shade700,
                    ),
                  if (_requestPhotographyVas)
                    _summaryRow(
                      isAr ? 'خدمة التصوير الاحترافي:' : 'Photo VAS Requested:',
                      '$_photographyCount items (+AED ${_photographyCount * CommercialModel.vasProductPhotographyPerItem})',
                      textColor: AppColors.bluePrimary,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(isAr ? 'تم والعودة للوحة المتجر' : 'Done & Return to Hub'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor ?? AppColors.textPrimary,
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
          isAr ? 'فحص واستلام البضائع (بالعدد والتلف)' : 'Cargo Intake & Count Inspection',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operational Guidance Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_rounded, color: AppColors.bluePrimary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'بروتوكول الاستلام والفحص لـ NXN' : 'NXN Intake Receiving Protocol',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.bluePrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'يتم مطابقة العدد الفعلي المستلم، وتوثيق أي تلفيات بالصور فوراً، مع خيار طلب تصوير احترافي لعرض المنتجات بالسوق.'
                                : 'Physical count verification against ASN manifest. Damages require photo capture for warranty protection.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Count Verification Section
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
                          child: Text(
                            isAr ? '1. مطابقة العدد الفعلي' : '1. Physical Count Verification',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAr ? 'المتوقع: $_expectedCount طرد' : 'Expected: $_expectedCount units',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _receivedCountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'العدد الفعلي المستلم *' : 'Total Received Count *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.inventory_2_outlined),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return isAr ? 'مطلوب' : 'Required';
                              if (int.tryParse(v) == null) return isAr ? 'رقم غير صحيح' : 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _damagedCountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'عدد القطع التالفة' : 'Damaged Count',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.broken_image_outlined, color: Colors.red),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final dmg = int.tryParse(v);
                              if (dmg == null) return isAr ? 'رقم غير صحيح' : 'Invalid';
                              if (dmg > _receivedCount) return isAr ? 'أكثر من المستلم' : '> Received';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _damagedCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _damagedCount > 0 ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _damagedCount > 0 ? Icons.warning_amber_rounded : Icons.verified_rounded,
                            color: _damagedCount > 0 ? Colors.red.shade700 : const Color(0xFF10AC84),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _damagedCount > 0
                                  ? (isAr
                                      ? 'تم رصد $_damagedCount طرد تالف! سيتم عزلها في منطقة الحجر، وطلب إرفاق صور.'
                                      : '$_damagedCount damaged units detected! Quarantined for merchant claim & photo required.')
                                  : (isAr
                                      ? 'جميع القطع المستلمة ($_soundCount طرد) بحالة ممتازة وجاهزة للتخزين على الرف.'
                                      : 'All $_soundCount units verified intact and cleared for standard shelf placement.'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _damagedCount > 0 ? Colors.red.shade800 : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Damage Photos Section (Active if damages > 0)
              if (_damagedCount > 0) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? '2. توثيق صور التلفيات (إلزامي)' : '2. Damage Photo Evidence (Mandatory)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_damageImages.length} ${isAr ? 'صور' : 'Photos'}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _damageDescriptionCtrl,
                        decoration: InputDecoration(
                          labelText: isAr ? 'وصف حالة الضرر أو التلف' : 'Damage Description / Notes',
                          hintText: isAr ? 'مثال: تمزق كرتون خارجي وكسر عبوة زجاجية' : 'e.g. Outer carton crushed, wet spot',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      // Photo previews
                      if (_damageImages.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _damageImages.length,
                            itemBuilder: (ctx, i) => Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(_damageImages[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 14,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _damageImages.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _showImageSourcePicker,
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.red),
                        label: Text(
                          isAr ? 'التقاط صورة للضرر (كاميرا / معرض)' : 'Take Photo of Damage (Camera/Gallery)',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Value Added Service: Product Photography for Online Listing
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _requestPhotographyVas ? const Color(0xFF10AC84) : Colors.grey.shade200,
                    width: _requestPhotographyVas ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10AC84).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF10AC84), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isAr ? 'خدمة التصوير الاحترافي للمتجر' : 'Product Photography for Marketplace',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10AC84),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAr ? 'قيمة مضافة' : 'VAS',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr
                                    ? 'استوديو NXN يقوم بتصوير منتجاتك بدقة عالية بخلفية بيضاء جاهزة لعرضها فوراً في السوق (15 د.إ / منتج).'
                                    : 'NXN studio shoots 4K white-background photos of your items for instant marketplace listing (AED 15/item).',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _requestPhotographyVas,
                          activeThumbColor: const Color(0xFF10AC84),
                          onChanged: (val) => setState(() => _requestPhotographyVas = val),
                        ),
                      ],
                    ),
                    if (_requestPhotographyVas) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'عدد المنتجات المطلوب تصويرها:' : 'Number of Items to Shoot:',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _photographyCount > 1
                                    ? () => setState(() => _photographyCount--)
                                    : null,
                              ),
                              Text(
                                '$_photographyCount',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(() => _photographyCount++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'رسوم خدمة التصوير (+5% ضريبة):' : 'Photography Fee (+5% VAT):',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                            ),
                            Text(
                              'AED ${(_photographyCount * CommercialModel.vasProductPhotographyPerItem * 1.05).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIntake,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isAr ? 'اعتماد محضر الاستلام وحفظ البضائع 📦' : 'Certify Intake & Store on Shelves 📦',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
