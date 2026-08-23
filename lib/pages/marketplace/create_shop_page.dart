import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../payment_page.dart';
import '../../models/invoice.dart';
import '../../providers/user_provider.dart';

class CreateShopPage extends StatefulWidget {
  const CreateShopPage({super.key});

  @override
  State<CreateShopPage> createState() => _CreateShopPageState();
}

class _CreateShopPageState extends State<CreateShopPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _licenseNameCtrl = TextEditingController();
  bool _isLoading = false;
  final MarketplaceService _service = MarketplaceService();

  Future<void> _submitShop() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final res = await _service.createShop(
        _shopNameCtrl.text.trim(),
        _licenseNameCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'تم تسجيل المتجر! يرجى دفع رسوم الإعداد لمتابعة الطلب.'
              : 'Shop registered! Please pay the setup fee to apply.'),
        ));

        final setupInvoice = Invoice(
          id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
          number:
              'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          warehouseName: 'Shop Verification Setup Fee',
          date: DateTime.now(),
          amount: 150.0,
          vat: 7.50,
          paid: false,
          type: InvoiceType.generic,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentsPage(
              initialInvoice: setupInvoice,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'فشل إنشاء المتجر. يرجى المحاولة مرة أخرى.'
              : 'Failed to create shop. Please try again.'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إعداد متجر السوق' : 'Setup Marketplace Shop'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return InkWell(
                onTap: () => localeProvider.toggleLocale(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded,
                          color: AppColors.bluePrimary, size: 16),
                      const SizedBox(width: 4),
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
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'كن تاجراً معتمداً' : 'Become a Verified Seller',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'أدخل بيانات عملك أدناه للتقدم بطلب الحصول على ملف متجر معتمد في سوق NXN.'
                    : 'Enter your business details below to apply for a verified shop profile on the NXN Marketplace.',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _shopNameCtrl,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'اسم المتجر (الاسم المعروض)'
                      : 'Shop Name (Display Name)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.storefront),
                ),
                validator: (v) => v!.isEmpty
                    ? (isAr
                        ? 'يرجى إدخال اسم المتجر'
                        : 'Please enter your shop name')
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _licenseNameCtrl,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'اسم الرخصة التجارية الحكومية'
                      : 'Government License Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                ),
                validator: (v) => v!.isEmpty
                    ? (isAr
                        ? 'يرجى إدخال اسم الرخصة التجارية الرسمية'
                        : 'Please enter your official license name')
                    : null,
              ),
              const SizedBox(height: 20),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  if (userProvider.isDocumentUploaded) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Colors.green, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr
                                      ? 'تم رفع مستند التوثيق التجاري ✓'
                                      : 'Business Documents Uploaded & Verified ✓',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.green),
                                ),
                                Text(
                                  userProvider.documentFileName ??
                                      'Trade_License_CN2891048.pdf',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isAr
                              ? 'إرسال للتحقق والاعتماد'
                              : 'Submit for Verification',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
