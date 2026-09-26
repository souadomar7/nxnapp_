import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/locale_provider.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart';

class AddProductPage extends StatefulWidget {
  final SmeProduct? product;
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '50');

  String _selectedCategory = 'General';
  bool _isLoading = false;
  File? _imageFile;
  String? _existingPhotoUrl;
  final ImagePicker _picker = ImagePicker();
  final MarketplaceService _service = MarketplaceService();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'Food & Beverage', 'nameEn': 'Food & Beverage', 'nameAr': 'أغذية ومشروبات', 'icon': Icons.coffee_rounded, 'color': Color(0xFFD97706)},
    {'id': 'Electronics', 'nameEn': 'Electronics', 'nameAr': 'إلكترونيات', 'icon': Icons.devices_rounded, 'color': Color(0xFF2563EB)},
    {'id': 'Flowers & Gifts', 'nameEn': 'Flowers & Gifts', 'nameAr': 'زهور وهدايا', 'icon': Icons.card_giftcard_rounded, 'color': Color(0xFFDB2777)},
    {'id': 'Health & Beauty', 'nameEn': 'Health & Beauty', 'nameAr': 'صحة وجمال', 'icon': Icons.spa_rounded, 'color': Color(0xFF059669)},
    {'id': 'Fashion', 'nameEn': 'Fashion', 'nameAr': 'أزياء', 'icon': Icons.checkroom_rounded, 'color': Color(0xFF7C3AED)},
    {'id': 'General', 'nameEn': 'General', 'nameAr': 'عام', 'icon': Icons.inventory_2_rounded, 'color': Color(0xFF4B5563)},
  ];

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _nameArController.text = widget.product!.nameAr ?? '';
      _descController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toStringAsFixed(2);
      _qtyController.text = widget.product!.quantity.toString();
      _existingPhotoUrl = widget.product!.photoUrl;
      _selectedCategory = widget.product!.category ?? 'General';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _adjustQuantity(int delta) {
    final current = int.tryParse(_qtyController.text) ?? 0;
    final next = (current + delta).clamp(1, 99999);
    setState(() => _qtyController.text = next.toString());
  }

  Future<void> _pickImage() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'إضافة صورة المنتج' : 'Select Product Photo',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.bluePrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt_rounded, color: AppColors.bluePrimary, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'الكاميرا' : 'Camera',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10AC84).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10AC84).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.photo_library_rounded, color: Color(0xFF10AC84), size: 32),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'المعرض' : 'Gallery',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10AC84)),
                          ),
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

    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final qty = int.tryParse(_qtyController.text) ?? 1;
      String photoUrl = _existingPhotoUrl ?? '';

      if (_imageFile != null) {
        final uploaded = await _service.uploadImage(_imageFile!);
        if (uploaded != null && uploaded.isNotEmpty) {
          photoUrl = uploaded;
        }
      }

      if (!mounted) {
        return;
      }
      final isAr = Localizations.localeOf(context).languageCode == 'ar';

      if (_isEditMode) {
        final supabase = Supabase.instance.client;
        await supabase.from('sme_products').update({
          'name': _nameController.text.trim(),
          'name_ar': _nameArController.text.trim().isNotEmpty ? _nameArController.text.trim() : null,
          'description': _descController.text.trim(),
          'price': price,
          'quantity': qty,
          'category': _selectedCategory,
          if (photoUrl.isNotEmpty) 'photo_url': photoUrl,
        }).eq('id', widget.product!.id);

        MarketplaceService.updateNotifier.value++;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(isAr ? '✅ تم تحديث المنتج بنجاح!' : '✅ Product updated successfully!'),
          ));
          Navigator.pop(context, true);
        }
      } else {
        await _service.addProduct(
          _nameController.text.trim(),
          _descController.text.trim(),
          price,
          photoUrl,
          quantity: qty,
        );

        // Update optional category & name_ar on newly created product
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            await Supabase.instance.client.from('sme_products').update({
              'category': _selectedCategory,
              'name_ar': _nameArController.text.trim().isNotEmpty ? _nameArController.text.trim() : null,
            }).eq('seller_id', user.id).order('created_at', ascending: false).limit(1);
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(isAr ? '🎉 تم نشر المنتج على المتجر بنجاح!' : '🎉 Product published to Marketplace!'),
          ));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final priceVal = double.tryParse(_priceController.text) ?? 0.0;
    final netVal = (priceVal * 0.95).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode
              ? (isAr ? 'تعديل بيانات المنتج' : 'Edit Product')
              : (isAr ? 'إضافة منتج جديد' : 'Add New Product'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return TextButton(
                onPressed: () => localeProvider.toggleLocale(),
                child: Text(
                  isAr ? 'EN' : 'العربية',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. IMAGE UPLOAD SECTION ──────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (_imageFile != null || _existingPhotoUrl != null)
                          ? AppColors.bluePrimary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_imageFile != null)
                          Image.file(_imageFile!, fit: BoxFit.cover)
                        else if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty)
                          Image.network(_existingPhotoUrl!, fit: BoxFit.cover)
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade50.withValues(alpha: 0.5), Colors.white],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_rounded, size: 36, color: AppColors.bluePrimary),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isAr ? 'التقط صورة أو اختر من المعرض' : 'Upload or Snap Product Photo',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAr ? 'JPG, PNG بجودة واضحة' : 'High resolution JPG or PNG',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        if (_imageFile != null || (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty))
                          Positioned(
                            bottom: 12,
                            right: isAr ? null : 12,
                            left: isAr ? 12 : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAr ? 'تغيير الصورة' : 'Change Photo',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── 2. CATEGORY SELECTOR CHIPS ──────────────────────────────
              Text(
                isAr ? 'تصنيف المنتج' : 'Product Category',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat['id'];
                    final color = cat['color'] as Color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['id'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(cat['icon'] as IconData, size: 18, color: isSelected ? color : Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? cat['nameAr'] as String : cat['nameEn'] as String,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                                color: isSelected ? color : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── 3. PRODUCT INFORMATION CARD ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'معلومات المنتج' : 'Product Details',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم المنتج بالإنجليزية *' : 'Product Title (EN) *',
                        hintText: 'e.g. Specialty Cold Brew Coffee 500ml',
                        prefixIcon: const Icon(Icons.title_rounded, color: AppColors.bluePrimary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'حقل مطلوب' : 'Required field') : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameArController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم المنتج بالعربية (اختياري)' : 'Product Title (AR - Optional)',
                        hintText: 'مثال: قهوة كولد برو فاخرة 500 مل',
                        prefixIcon: const Icon(Icons.translate_rounded, color: Color(0xFF10AC84)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isAr ? 'وصف المنتج والمواصفات' : 'Description & Specifications',
                        hintText: isAr ? 'اكتب تفاصيل وميزات المنتج للمشتري...' : 'Enter product features, ingredients, or specifications...',
                        prefixIcon: const Icon(Icons.notes_rounded, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 4. PRICING & STOCK CONTROLLER ────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'التسعير والمخزون' : 'Pricing & Inventory',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: isAr ? 'سعر البيع *' : 'Retail Price *',
                              hintText: '0.00',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  isAr ? 'د.إ' : 'AED',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.bluePrimary),
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return isAr ? 'مطلوب' : 'Required';
                              final val = double.tryParse(v.trim());
                              if (val == null) return isAr ? 'رقم غير صحيح' : 'Invalid number';
                              if (val < 1.0) return isAr ? 'الحد الأدنى للسعر 1 درهم' : 'Minimum price is AED 1';
                              if (val > 500000.0) return isAr ? 'السعر يتجاوز الحد الأقصى' : 'Price exceeds max limit';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'صافي أرباحك' : 'Est. Net', style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                                const SizedBox(height: 2),
                                Text(
                                  'AED ${netVal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.bluePrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stock Counter Stepper
                    Text(
                      isAr ? 'الكمية المتوفرة في المخزون' : 'Available Stock Quantity',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _stepBtn(icon: Icons.remove, onPressed: () => _adjustQuantity(-1)),
                          _quickStepChip('-10', () => _adjustQuantity(-10)),
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              decoration: const InputDecoration(border: InputBorder.none),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return isAr ? 'مطلوب' : 'Required';
                                final val = int.tryParse(v.trim());
                                if (val == null) return isAr ? 'رقم غير صحيح' : 'Invalid';
                                if (val < 0) return isAr ? 'لا يمكن أن تكون الكمية سالبة' : 'Cannot be negative';
                                if (val > 100000) return isAr ? 'الكمية تتجاوز الحد المسموح' : 'Exceeds maximum limit';
                                return null;
                              },
                            ),
                          ),
                          _quickStepChip('+10', () => _adjustQuantity(10)),
                          _stepBtn(icon: Icons.add, onPressed: () => _adjustQuantity(1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. LIVE MARKETPLACE PREVIEW ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'معاينة مباشرة في المتجر' : 'Live Marketplace Card Preview',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAr ? 'مباشر' : 'Live',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              image: _imageFile != null
                                  ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                  : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(_existingPhotoUrl!), fit: BoxFit.cover)
                                      : null),
                            ),
                            child: (_imageFile == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty))
                                ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.trim().isNotEmpty
                                      ? _nameController.text.trim()
                                      : (isAr ? 'اسم المنتج' : 'Product Name'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _selectedCategory,
                                        style: const TextStyle(fontSize: 10, color: AppColors.bluePrimary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_qtyController.text} in stock',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'AED ${priceVal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.bluePrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isEditMode ? Icons.check_circle_rounded : Icons.rocket_launch_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isEditMode
                            ? (isAr ? 'حفظ التعديلات' : 'Save Changes')
                            : (isAr ? 'نشر المنتج في المتجر' : 'Publish to Marketplace'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _stepBtn({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _quickStepChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
