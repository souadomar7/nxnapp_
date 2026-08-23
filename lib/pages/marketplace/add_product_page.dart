import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/locale_provider.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../l10n/app_localizations.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasWarehouseSub = false;
  final TextEditingController _qtyController = TextEditingController(text: '50');
  final MarketplaceService _service = MarketplaceService();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sub = await _service.hasActiveSubscription();
      if (mounted) setState(() => _hasWarehouseSub = sub);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
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
      final shop = await _service.getMyShop();
      final products = await _service.getProducts();
      // Cap is bypassed by Featured status, NOT by approval status.
      // An approved-but-not-featured shop is still subject to the 5-product limit.
      final bool featuredActive = shop?.featuredActive ?? false;

      if (!featuredActive && products.length >= 5) {
        setState(() => _isLoading = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Free Tier Limit Reached'),
              content: const Text(
                'Free shops can list a maximum of 5 products.\n\n'
                'Upgrade to a Featured shop to enjoy unlimited product listings '
                'plus top placement in the buyer marketplace!'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.bluePrimary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Exit Add Product screen
                  },
                  child: const Text('Go Featured ⭐'),
                )
              ],
            ),
          );
        }
        return;
      }

      final price = double.parse(_priceController.text);
      String photoUrl = '';
      if (_imageFile != null) {
        final url = await _service.uploadImage(_imageFile!);
        if (url != null) photoUrl = url;
      }

      final qty = int.tryParse(_qtyController.text) ?? 50;
      await _service.addProduct(
        _nameController.text,
        _descController.text,
        price,
        photoUrl,
        quantity: qty,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      // DB trigger enforced the product limit (authenticated users)
      if (e.message.contains('product_limit_reached')) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Free Tier Limit Reached'),
              content: Text(e.message.replaceFirst('product_limit_reached: ', '')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: Text(
          AppLocalizations.of(context)!.addProductTitle,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              final isAr = localeProvider.locale.languageCode == 'ar';
              return InkWell(
                onTap: () => localeProvider.toggleLocale(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.bluePrimary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? 'EN' : 'العربية',
                        style: const TextStyle(
                          color: AppColors.bluePrimary,
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
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. HERO PHOTO UPLOADER ──────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF003C8E).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: _imageFile != null
                                ? AppColors.bluePrimary
                                : Colors.grey.shade300,
                            width: _imageFile != null ? 2 : 1.5,
                          ),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.bluePrimary.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_rounded,
                                      color: AppColors.bluePrimary,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr ? 'اضغط لرفع صورة' : 'Tap to upload photo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      if (_imageFile != null)
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.bluePrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ─── 2. MODERN FORM INPUTS ──────────────────────────────────
              _buildModernTextField(
                controller: _nameController,
                label: isAr ? 'اسم المنتج *' : 'Product Name *',
                hint: isAr ? 'مثال: حبوب إسبريسو فاخرة' : 'e.g. Premium Espresso Beans',
                icon: Icons.shopping_bag_outlined,
                validator: (val) => val == null || val.isEmpty
                    ? AppLocalizations.of(context)!.requiredError
                    : null,
              ),

              const SizedBox(height: 18),

              _buildModernTextField(
                controller: _descController,
                label: isAr ? 'وصف المنتج' : 'Description',
                hint: isAr ? 'اكتب مواصفات المنتج وميزاته...' : 'Enter product features, specs & details...',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 18),

              _buildModernTextField(
                controller: _priceController,
                label: isAr ? 'السعر (درهم إماراتي) *' : 'Price (AED) *',
                hint: '0.00',
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: isAr ? 'درهم ' : 'AED ',
                validator: (val) {
                  if (val == null || val.isEmpty) return AppLocalizations.of(context)!.requiredError;
                  if (double.tryParse(val) == null) return AppLocalizations.of(context)!.invalidNumberError;
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // ─── 3. FULFILLMENT CHANNEL CARD ────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _hasWarehouseSub
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hasWarehouseSub
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFFFDE68A),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _hasWarehouseSub
                            ? AppColors.bluePrimary
                            : Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _hasWarehouseSub ? Icons.sync_rounded : Icons.storefront_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _hasWarehouseSub
                                      ? (isAr ? 'مربوط بشبكة مستودعات NXN' : 'Connected to NXN Warehouse Stock')
                                      : (isAr ? 'شحن عبر التاجر' : 'Merchant Self-Fulfillment'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _hasWarehouseSub
                                        ? const Color(0xFF1E40AF)
                                        : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _hasWarehouseSub ? Colors.green : Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasWarehouseSub
                                ? (isAr
                                    ? 'المنتج مربوط بأرفف المستودع المستأجرة. يتم الخصم تلقائياً من المخزون الذكي مع كل طلب شراء.'
                                    : 'Product stock is linked to your leased shelves and auto-decremented in Smart Inventory upon buyer order.')
                                : (isAr
                                    ? 'يمكنك التداول بشحن التاجر الخاص، أو استئجار أرفف للحصول على التجهيز التلقائي الشامل.'
                                    : 'You fulfill orders directly, or lease shelf space to activate automated NXN warehouse stock sync.'),
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasWarehouseSub
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.amber.shade900,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _buildModernTextField(
                controller: _qtyController,
                label: isAr ? 'كمية المخزون الابتدائية *' : 'Initial Stock Quantity *',
                hint: '50',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return AppLocalizations.of(context)!.requiredError;
                  if (int.tryParse(val) == null) return AppLocalizations.of(context)!.invalidNumberError;
                  return null;
                },
              ),

              const SizedBox(height: 24),

              Text(
                isAr
                    ? 'ملاحظة: إذا كان متجرك معتمداً، سيظهر هذا المنتج فوراً في السوق المعتمد للعملاء.'
                    : 'Note: If your shop is Verified, this product will be immediately visible on the Public Marketplace.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // ─── 4. PREMIUM SUBMIT BUTTON ────────────────────────────────
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          AppLocalizations.of(context)!.saveProductButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          prefixIcon: Icon(icon, color: AppColors.bluePrimary, size: 22),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.bluePrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
