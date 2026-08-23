import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/marketplace_models.dart';
import '../../services/marketplace_service.dart';
import '../../theme.dart';

class PublicProductDetailPage extends StatefulWidget {
  final SmeProduct product;

  const PublicProductDetailPage({super.key, required this.product});

  @override
  State<PublicProductDetailPage> createState() => _PublicProductDetailPageState();
}

class _PublicProductDetailPageState extends State<PublicProductDetailPage> {
  final MarketplaceService _service = MarketplaceService();
  int _quantity = 1;

  void _showCheckoutSheet() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    String selectedEmirate = 'Dubai';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final total = widget.product.price * _quantity;
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'إتمام الشراء' : 'Buyer Checkout',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Item summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          isAr
                              ? '$_quantity × ${widget.product.price.toStringAsFixed(2)} درهم = ${total.toStringAsFixed(2)} درهم'
                              : '$_quantity × AED ${widget.product.price.toStringAsFixed(2)} = AED ${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.bluePrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الاسم الكامل *' : 'Full Name *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isAr ? 'رقم الهاتف (واتساب) *' : 'Phone Number (WhatsApp) *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: isAr ? 'عنوان التوصيل *' : 'Delivery Address *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedEmirate,
                    decoration: InputDecoration(
                      labelText: isAr ? 'الإمارة *' : 'Emirate *',
                      border: const OutlineInputBorder(),
                    ),
                    items: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Al Ain', 'Ajman', 'RAK', 'Fujairah', 'UAQ']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedEmirate = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty ||
                                  phoneController.text.trim().isEmpty ||
                                  addressController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(isAr ? 'يرجى تعبئة جميع الحقول المطلوبة.' : 'Please fill all required fields.')),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);

                              final fullAddress = '${addressController.text.trim()}, $selectedEmirate';
                              final success = await _service.createBuyerOrder(
                                buyerName: nameController.text.trim(),
                                buyerPhone: phoneController.text.trim(),
                                product: widget.product,
                                quantity: _quantity,
                                deliveryAddress: fullAddress,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted && success) {
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(isAr ? 'تم إرسال الطلب بنجاح!' : 'Order Placed!'),
                                      ],
                                    ),
                                    content: Text(
                                      isAr
                                          ? 'تم إرسال طلبك لشراء ${widget.product.name} (${total.toStringAsFixed(2)} درهم) بنجاح! تم إخطار التاجر للتجهيز والتوصيل.'
                                          : 'Your order for ${widget.product.name} (AED ${total.toStringAsFixed(2)}) '
                                              'has been placed successfully! The merchant has been notified for dispatch.',
                                    ),
                                    actions: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                                        label: Text(isAr ? 'بيانات الطلب عبر واتساب' : 'WhatsApp Order Payload', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          final text = Uri.encodeComponent(
                                            '🛍️ *NXN Hub Marketplace Order*\n'
                                            '• Item: ${widget.product.name}\n'
                                            '• Qty: $_quantity\n'
                                            '• Total: AED ${total.toStringAsFixed(2)} (incl. 5% VAT)\n'
                                            '• Buyer: ${nameController.text.trim()}\n'
                                            '• Phone: ${phoneController.text.trim()}\n'
                                            '• Address: $fullAddress\n'
                                            '• FTA TRN: 100492817300003'
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('WhatsApp API Payload generated: wa.me/?text=$text'),
                                              backgroundColor: Colors.green.shade800,
                                            ),
                                          );
                                        },
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(dialogCtx),
                                        child: Text(isAr ? 'حسناً' : 'OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isAr ? 'دفع ${total.toStringAsFixed(2)} درهم وتأكيد الطلب' : 'Pay AED ${total.toStringAsFixed(2)} & Place Order',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.bluePrimary, size: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: widget.product.photoUrl != null
                    ? DecorationImage(image: NetworkImage(widget.product.photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: widget.product.photoUrl == null
                  ? const Center(child: Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey))
                  : null,
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.bluePrimary.withValues(alpha: 0.1),
                          child: const Icon(Icons.storefront, color: AppColors.bluePrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.shopName ?? (isAr ? 'تاجر NXN' : 'NXN Merchant'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (widget.product.isShopApproved)
                                Row(
                                  children: [
                                    const Icon(Icons.verified, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(isAr ? 'تاجر معتمد' : 'Verified Seller', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Product Info
                  Text(
                    isAr ? (widget.product.nameAr ?? _getArabicProductName(widget.product.name)) : widget.product.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? '${widget.product.price.toStringAsFixed(2)} درهم' : 'AED ${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.bluePrimary),
                  ),
                  const SizedBox(height: 24),

                  Text(isAr ? 'الوصف' : 'Description', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description ?? (isAr ? 'لا يوجد وصف للمنتج.' : 'No description provided.'),
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // Quantity Selector
                  Row(
                    children: [
                      Text(isAr ? 'الكمية' : 'Quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Spacing for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAr ? 'الإجمالي' : 'Total Price', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  isAr ? '${(widget.product.price * _quantity).toStringAsFixed(2)} درهم' : 'AED ${(widget.product.price * _quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.bluePrimary),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _showCheckoutSheet,
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  label: Text(
                    isAr ? 'شراء الآن' : 'Buy Now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _getArabicProductName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('espresso') || lower.contains('beans')) return 'حبوب إسبريسو فاخرة';
  if (lower.contains('earbuds') || lower.contains('wireless')) return 'سماعات لاسلكية برو';
  if (lower.contains('flower') || lower.contains('rose')) return 'باقة زهور طبيعية';
  if (lower.contains('inbound') || lower.contains('sto')) return 'دفعة شحنة واردة (STO)';
  if (lower.contains('refurbished') || lower.contains('open box')) return '$name (مجدد / مفتوح)';
  return name;
}
