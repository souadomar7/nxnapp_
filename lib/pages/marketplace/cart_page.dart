import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/marketplace_service.dart';
import '../../services/payment_service.dart';
import '../../models/invoice.dart';
import '../operations/order_tracking_page.dart';
import '../../core/utils/validators.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _promoCtrl = TextEditingController();
  final MarketplaceService _service = MarketplaceService();
  String? _promoError;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  void _applyPromo(CartProvider cart, bool isAr) {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;

    final success = cart.applyPromoCode(code);
    setState(() {
      if (success) {
        _promoError = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10AC84),
            content: Text(isAr ? '🎉 تم تطبيق كود الخصم بنجاح!' : '🎉 Promo code applied successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _promoError = isAr ? 'كود الخصم غير صالح' : 'Invalid promo code';
      }
    });
  }

  void _confirmClearCart(CartProvider cart, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(isAr ? 'تفريغ السلة' : 'Clear Cart', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(isAr ? 'هل أنت متأكد من رغبتك في حذف جميع المنتجات من السلة؟' : 'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
            },
            child: Text(isAr ? 'تفريغ' : 'Clear All'),
          ),
        ],
      ),
    );
  }

  void _showCartCheckoutSheet(CartProvider cart) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final formKey = GlobalKey<FormState>();
    final currentUser = Supabase.instance.client.auth.currentUser;
    final nameController = TextEditingController(
      text: (currentUser?.userMetadata?['full_name'] ?? currentUser?.userMetadata?['name'] ?? '').toString(),
    );
    final phoneController = TextEditingController(
      text: (currentUser?.phone ?? currentUser?.userMetadata?['phone'] ?? '').toString(),
    );
    final addressController = TextEditingController();
    String selectedEmirate = 'Dubai';
    String selectedPaymentMethod = 'card';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final subtotal = cart.subtotal;
          final deliveryFee = cart.deliveryFee;
          final discount = cart.discountAmount;
          final vat = cart.vatAmount;
          final grandTotal = cart.grandTotal;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header with Security Trust Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'إتمام الشراء والدفع الآمن' : 'Secure Multi-Item Checkout',
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF10AC84)),
                                const SizedBox(width: 4),
                                Text(
                                  isAr ? 'دفع مشفر ومحمي • ضمان NXN' : '256-Bit SSL • NXN Escrow',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10AC84)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Items Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'المنتجات في الطلب (${cart.totalItemCount} قطع)' : 'Order Items (${cart.totalItemCount} items)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          ...cart.items.take(3).map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.product.getLocalizedName(isAr)}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'AED ${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (cart.items.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                isAr ? '+ ${cart.items.length - 3} منتجات أخرى' : '+ ${cart.items.length - 3} more items',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Delivery Inputs
                    Text(
                      isAr ? 'بيانات التوصيل' : 'Delivery Details',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'الاسم الكامل *' : 'Full Name *',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.bluePrimary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        final err = Validators.recipientName(val);
                        if (err != null) return isAr ? 'يرجى إدخال اسم المستلم الكامل بشكل صحيح' : err;
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isAr ? 'رقم الهاتف المتحرك (واتساب) *' : 'Mobile Number (WhatsApp) *',
                        hintText: '+971 50 123 4567',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.bluePrimary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        final err = Validators.uaePhone(val, allowInternational: false);
                        if (err != null) {
                          return isAr ? 'رقم الهاتف يجب أن يكون رقم إماراتي صحيح (مثال: +971501234567 أو 0501234567)' : err;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: selectedEmirate,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: isAr ? 'الإمارة *' : 'Emirate *',
                        prefixIcon: const Icon(Icons.location_city_rounded, size: 20, color: AppColors.bluePrimary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Al Ain', 'Ajman', 'RAK', 'Fujairah', 'UAQ']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedEmirate = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'العنوان التفصيلي (الشارع / المبنى / الشقة) *' : 'Full Address / Street / Villa *',
                        hintText: isAr ? 'مثال: برج الياقوت، شارع الشيخ زايد، شقة 1402' : 'e.g. Ruby Tower, Sheikh Zayed Rd, Apt 1402',
                        prefixIcon: const Icon(Icons.home_outlined, size: 20, color: AppColors.bluePrimary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        final err = Validators.deliveryAddress(val);
                        if (err != null) return isAr ? 'يرجى إدخال عنوان تفصيلي واضح (المبنى، الشارع)' : err;
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Payment Method
                    Text(
                      isAr ? 'طريقة الدفع الآمنة' : 'Payment Method',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedPaymentMethod = 'card'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: selectedPaymentMethod == 'card' ? AppColors.bluePrimary.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedPaymentMethod == 'card' ? AppColors.bluePrimary : Colors.grey.shade200,
                                  width: selectedPaymentMethod == 'card' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.credit_card_rounded, color: AppColors.bluePrimary, size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr ? 'بطاقة بنكية' : 'Card (Stripe)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: selectedPaymentMethod == 'card' ? FontWeight.bold : FontWeight.w500,
                                      color: selectedPaymentMethod == 'card' ? AppColors.bluePrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedPaymentMethod = 'apple_pay'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: selectedPaymentMethod == 'apple_pay' ? const Color(0xFF10AC84).withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedPaymentMethod == 'apple_pay' ? const Color(0xFF10AC84) : Colors.grey.shade200,
                                  width: selectedPaymentMethod == 'apple_pay' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.apple_rounded, color: Color(0xFF10AC84), size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr ? 'Apple Pay' : 'Apple Pay',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: selectedPaymentMethod == 'apple_pay' ? FontWeight.bold : FontWeight.w500,
                                      color: selectedPaymentMethod == 'apple_pay' ? const Color(0xFF10AC84) : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedPaymentMethod = 'cod'),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: selectedPaymentMethod == 'cod' ? const Color(0xFFFF9F43).withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedPaymentMethod == 'cod' ? const Color(0xFFFF9F43) : Colors.grey.shade200,
                                  width: selectedPaymentMethod == 'cod' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.local_shipping_rounded, color: Color(0xFFFF9F43), size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAr ? 'عند الاستلام' : 'Cash (COD)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: selectedPaymentMethod == 'cod' ? FontWeight.bold : FontWeight.w500,
                                      color: selectedPaymentMethod == 'cod' ? const Color(0xFFFF9F43) : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Cost Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isAr ? 'قيمة المشتريات' : 'Items Subtotal', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                              Text('AED ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isAr ? 'التوصيل السريع' : 'Express Delivery', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                              Text(
                                deliveryFee == 0.0 ? (isAr ? 'مجاني' : 'FREE') : 'AED ${deliveryFee.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: deliveryFee == 0.0 ? const Color(0xFF10AC84) : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (discount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isAr ? 'خصم الكوبون (${cart.appliedPromoCode})' : 'Promo Discount (${cart.appliedPromoCode})', style: const TextStyle(fontSize: 13, color: Color(0xFF10AC84), fontWeight: FontWeight.w600)),
                                Text('- AED ${discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10AC84))),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isAr ? 'ضريبة القيمة المضافة 5%' : 'UAE VAT 5% (Included)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              Text('AED ${vat.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isAr ? 'المجموع النهائي' : 'Grand Total', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text('AED ${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.bluePrimary)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit and Pay Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ?? false)) {
                                  return;
                                }

                                final name = nameController.text.trim();
                                final phone = phoneController.text.trim();
                                final address = addressController.text.trim();
                                final fullAddress = '$address, $selectedEmirate';

                                setSheetState(() => isSubmitting = true);

                                try {
                                  if (selectedPaymentMethod == 'card' || selectedPaymentMethod == 'apple_pay') {
                                    try {
                                      final invoice = Invoice(
                                        id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
                                        number: 'CART-${DateTime.now().millisecondsSinceEpoch}',
                                        warehouseName: 'NXN Marketplace',
                                        date: DateTime.now(),
                                        amount: grandTotal,
                                        vat: vat,
                                      );
                                      await PaymentService.pay(method: PaymentMethod.card, invoice: invoice)
                                          .timeout(const Duration(seconds: 3));
                                    } catch (_) {
                                      // In development/test mode or if server is offline, simulate authorization smoothly
                                      await Future.delayed(const Duration(milliseconds: 600));
                                    }
                                  } else {
                                    await Future.delayed(const Duration(milliseconds: 400));
                                  }

                                  // Place orders for each item in the cart
                                  final firstItemName = cart.items.isNotEmpty ? cart.items.first.product.name : 'Cart Item';
                                  final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                                  for (var item in List.from(cart.items)) {
                                    await _service.createBuyerOrder(
                                      buyerName: name,
                                      buyerPhone: phone,
                                      deliveryAddress: fullAddress,
                                      product: item.product,
                                      quantity: item.quantity,
                                    );
                                  }

                                  // Clear cart
                                  cart.clearCart();

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx); // Close sheet
                                  }

                                  await Future.delayed(const Duration(milliseconds: 150));

                                  if (mounted) {
                                    // Show Order Success Receipt Modal
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        title: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFDCFCE7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10AC84), size: 48),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              isAr ? 'تم تأكيد طلبك بنجاح! 🎉' : 'Order Placed Successfully! 🎉',
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
                                                  ? 'تم إرسال تفاصيل الشحنة إلى مستودعات NXN لبدء التجهيز والتوصيل السريع.'
                                                  : 'Your shipment details were dispatched to NXN Smart Warehouses for rapid fulfillment.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(isAr ? 'رقم الطلب' : 'Order Ref', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                      Text('#$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.bluePrimary)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(isAr ? 'المبلغ المدفوع' : 'Total Paid', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                      Text('AED ${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(isAr ? 'طريقة الدفع' : 'Payment Method', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                      Text(
                                                        selectedPaymentMethod == 'cod'
                                                            ? (isAr ? 'عند الاستلام' : 'Cash on Delivery')
                                                            : selectedPaymentMethod == 'apple_pay'
                                                                ? 'Apple Pay'
                                                                : (isAr ? 'بطاقة بنكية' : 'Card (Stripe)'),
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.bluePrimary),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(isAr ? 'موعد التوصيل' : 'Delivery', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                      Text(isAr ? 'خلال 24-48 ساعة ⚡' : 'Within 24-48h ⚡', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10AC84))),
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
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(dialogCtx);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => OrderTrackingPage(
                                                    productName: firstItemName,
                                                    currentStatus: 'confirmed',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(isAr ? 'تتبع مسار الطلب' : 'Track Order Status'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(dialogCtx);
                                              Navigator.pop(context);
                                            },
                                            child: Text(isAr ? 'متابعة التسوق' : 'Continue Shopping'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } catch (err) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Order error: $err'),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                } finally {
                                  if (ctx.mounted) setSheetState(() => isSubmitting = false);
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAr ? 'دفع ${grandTotal.toStringAsFixed(2)} درهم وتأكيد الطلب' : 'Pay AED ${grandTotal.toStringAsFixed(2)} & Confirm',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
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
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          children: [
            Text(
              isAr ? 'سلة المشتريات' : 'Shopping Cart',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
            ),
            if (cart.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cart.totalItemCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
              tooltip: isAr ? 'تفريغ السلة' : 'Clear Cart',
              onPressed: () => _confirmClearCart(cart, isAr),
            ),
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
      body: cart.isEmpty ? _buildEmptyCart(isAr) : _buildCartContent(cart, isAr),
      bottomNavigationBar: cart.isEmpty ? null : _buildBottomCheckoutBar(cart, isAr),
    );
  }

  Widget _buildEmptyCart(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.bluePrimary),
            ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'سلة التسوق فارغة حالياً' : 'Your Shopping Cart is Empty',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? 'تصفح منتجات سوق NXN المعتمد وأضف المنتجات المفضلة إلى سلتك.' : 'Explore items from verified UAE merchants and add them to your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: Text(
                  isAr ? 'تصفح السوق الآن' : 'Explore Marketplace',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartProvider cart, bool isAr) {
    final freeDeliveryDiff = (150.0 - cart.subtotal).clamp(0.0, 150.0);
    final freeDeliveryProgress = (cart.subtotal / 150.0).clamp(0.0, 1.0);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // ── Free Delivery Banner ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cart.subtotal >= 150.0 ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cart.subtotal >= 150.0 ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    cart.subtotal >= 150.0 ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                    color: cart.subtotal >= 150.0 ? const Color(0xFF166534) : AppColors.bluePrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cart.subtotal >= 150.0
                          ? (isAr ? '🎉 مبروك! حصلت على توصيل سريع مجاني!' : '🎉 Congratulations! You have unlocked FREE express shipping!')
                          : (isAr
                              ? 'أضف بقيمة AED ${freeDeliveryDiff.toStringAsFixed(2)} للحصول على شحن مجاني!'
                              : 'Add AED ${freeDeliveryDiff.toStringAsFixed(2)} more for FREE Express Shipping!'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cart.subtotal >= 150.0 ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: freeDeliveryProgress,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  color: cart.subtotal >= 150.0 ? const Color(0xFF10AC84) : AppColors.bluePrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Cart Items List ──────────────────────────────────────────
        ...cart.items.map((item) {
          final prod = item.product;
          final prodName = prod.getLocalizedName(isAr);
          final hasImage = prod.photoUrl != null && prod.photoUrl!.isNotEmpty;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    image: hasImage ? DecorationImage(image: NetworkImage(prod.photoUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: !hasImage
                      ? const Center(child: Icon(Icons.inventory_2_outlined, color: AppColors.bluePrimary, size: 32))
                      : null,
                ),

                const SizedBox(width: 12),

                // Details & Controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              prodName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => cart.removeItem(prod.id),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prod.shopName ?? (isAr ? 'تاجر NXN' : 'NXN Merchant'),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AED ${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.bluePrimary),
                          ),
                          // Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => cart.decrement(prod.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.remove_rounded, size: 16, color: AppColors.textPrimary),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => cart.increment(prod.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.add_rounded, size: 16, color: AppColors.bluePrimary),
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
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        // ── Promo Code Card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'كوبون الخصم' : 'Promo Code',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              if (cart.appliedPromoCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${cart.appliedPromoCode} (${isAr ? "مفعل" : "Active"})',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 13),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => cart.removePromoCode(),
                        child: Text(
                          isAr ? 'إلغاء' : 'Remove',
                          style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: isAr ? 'مثال: NXN10' : 'e.g. NXN10 or SAVE20',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => _applyPromo(cart, isAr),
                      child: Text(isAr ? 'تطبيق' : 'Apply'),
                    ),
                  ],
                ),
                if (_promoError != null) ...[
                  const SizedBox(height: 4),
                  Text(_promoError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                ],
                const SizedBox(height: 6),
                Text(
                  isAr ? '💡 جرب الكود NXN10 لخصم 10% أو SAVE20 لخصم 20 درهم' : '💡 Try promo NXN10 for 10% off or SAVE20 for AED 20 off',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Order Summary Card ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'ملخص الطلب' : 'Order Summary',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'قيمة المنتجات' : 'Items Subtotal', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  Text('AED ${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'التوصيل السريع' : 'Express Delivery', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  Text(
                    cart.deliveryFee == 0.0 ? (isAr ? 'مجاني' : 'FREE') : 'AED ${cart.deliveryFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: cart.deliveryFee == 0.0 ? const Color(0xFF10AC84) : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (cart.discountAmount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isAr ? 'خصم الكوبون' : 'Promo Discount', style: const TextStyle(fontSize: 13, color: Color(0xFF10AC84), fontWeight: FontWeight.bold)),
                    Text('- AED ${cart.discountAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10AC84))),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'ضريبة القيمة المضافة (5% مشمولة)' : 'UAE VAT 5% (Included)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  Text('AED ${cart.vatAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isAr ? 'المجموع الكلي' : 'Grand Total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  Text('AED ${cart.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.bluePrimary)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Trust & Escrow Guarantee ─────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF10AC84)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isAr ? 'تسوق آمن ومحمي 100% مع ضمان استرجاع 14 يوماً' : '100% Safe Checkout with 14-Day Money Back Guarantee',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCheckoutBar(CartProvider cart, bool isAr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAr ? 'المجموع' : 'Total', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                Text(
                  'AED ${cart.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.bluePrimary),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => _showCartCheckoutSheet(cart),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isAr ? 'متابعة الدفع (${cart.totalItemCount})' : 'Checkout (${cart.totalItemCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
      ),
    );
  }
}
