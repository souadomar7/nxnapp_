import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models/commercial_model.dart';
import '../../models/invoice.dart';
import '../../services/payment_service.dart';
import '../checkout_page.dart';
import '../operations/outbound_order_creation_page.dart';
import '../operations/inbound_intake_inspection_page.dart';
import 'add_product_page.dart';
import 'seller_products_page.dart';

class HomeSellerMarketplaceHubPage extends StatefulWidget {
  const HomeSellerMarketplaceHubPage({super.key});

  @override
  State<HomeSellerMarketplaceHubPage> createState() => _HomeSellerMarketplaceHubPageState();
}

class _HomeSellerMarketplaceHubPageState extends State<HomeSellerMarketplaceHubPage> {
  int _selectedContractMonths = 6;
  int _selectedShelvesCount = 2;
  bool _includePhotography = true;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final quote = CommercialModel.calculateShelfQuote(
      shelfCount: _selectedShelvesCount,
      durationMonths: _selectedContractMonths,
      includePhotography: _includePhotography,
      photographyItemCount: _selectedShelvesCount * 3,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.bluePrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? 'منصة الأسر المنتجة والشركات الصغيرة' : 'Home Sellers & SME Sales Hub',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.38),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'إضافة منتج' : 'Add Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner: Additional Sales Channel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              isAr ? 'قناة بيع إضافية للتجار' : 'Additional Sales Channel',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10AC84),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Fintx Gateway Active',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isAr
                        ? 'حوّل منزلك لمتجر احترافي، وخزّن بضاعتك برف قياسي بـ 100 درهم فقط!'
                        : 'Scale your home business with 100 AED standard shelves & unified delivery.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'تخزين آمن، توصيل سريع لعملائك في كافة الإمارات، تصوير احترافي، وتحصيل فوري لأموالك.'
                        : 'Secure micro-storage, UAE-wide next-day courier, 4K product photography & instant Fintx payouts.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Operational Actions Grid
            Text(
              isAr ? 'العمليات السريعة للتاجر' : 'Quick Operations',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    icon: Icons.outbox_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: isAr ? 'طلب شحن وتوزيع' : 'Outbound Dispatch',
                    subtitle: isAr ? 'سحب بضاعة وتوصيل للزبون' : 'Pick & pack order',
                    badge: isAr ? 'أمر توزيع' : 'Dispatch',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OutboundOrderCreationPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionTile(
                    icon: Icons.move_to_inbox_rounded,
                    color: const Color(0xFF10AC84),
                    title: isAr ? 'توريد بضاعة (Drop-off)' : 'Drop-off Intake',
                    subtitle: isAr ? 'تسليم بالعدد وفحص التلف' : 'Receiving & count check',
                    badge: isAr ? 'استلام' : 'Intake',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InboundIntakeInspectionPage()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    icon: Icons.add_a_photo_rounded,
                    color: const Color(0xFFEC4899),
                    title: isAr ? 'تصوير للمتجر (VAS)' : 'Product Photos',
                    subtitle: isAr ? '15 درهم / منتج بخلفية بيضاء' : '4K studio listing photos',
                    badge: isAr ? 'قيمة مضافة' : '15 AED',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddProductPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionTile(
                    icon: Icons.storefront_outlined,
                    color: const Color(0xFFF59E0B),
                    title: isAr ? 'منتجاتي والأسعار' : 'Manage Products',
                    subtitle: isAr ? 'تعديل الأسعار والكميات' : '100% price control',
                    badge: isAr ? 'السوق' : 'Catalog',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SellerProductsPage()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Simplified Storage Selling Model (Flat 100 AED + Contract Discounts)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.bluePrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shelves, color: AppColors.bluePrimary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'نموذج التخزين المبسط للأسر والشركات' : 'Simplified Standard Shelf Storage',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    isAr ? '100 درهم / رف قياسي شهرياً' : 'Flat AED 100 / shelf / mo',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAr ? '100 درهم/شهر' : 'AED 100/mo',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Shelf Count Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'عدد الأرفف المطلوبة:' : 'Number of Shelves:',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _selectedShelvesCount > 1
                                ? () => setState(() => _selectedShelvesCount--)
                                : null,
                          ),
                          Text(
                            '$_selectedShelvesCount ${isAr ? 'رفوف' : 'Shelves'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.bluePrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _selectedShelvesCount++),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Contract Duration Discount Chips
                  Text(
                    isAr ? 'مدة العقد والخصم التدريجي:' : 'Contract Duration & Discount:',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Row(
                    children: [
                      _contractChip(1, isAr ? 'شهر واحد' : '1 Mo', '0%', quote.durationMonths == 1),
                      const SizedBox(width: 6),
                      _contractChip(3, isAr ? '3 شهور' : '3 Mo', '-5%', quote.durationMonths == 3),
                      const SizedBox(width: 6),
                      _contractChip(6, isAr ? '6 شهور' : '6 Mo', '-10%', quote.durationMonths == 6),
                      const SizedBox(width: 6),
                      _contractChip(12, isAr ? 'سنة كاملة' : '1 Yr', '-20%', quote.durationMonths == 12),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // VAS Photography Toggle
                  InkWell(
                    onTap: () => setState(() => _includePhotography = !_includePhotography),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _includePhotography,
                              activeColor: AppColors.bluePrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) => setState(() => _includePhotography = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAr ? 'إضافة خدمة تصوير المنتجات للاستعراض بالسوق (+15 د.إ/صنف)' : 'Add Professional 4K Product Photography (+AED 15/item)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 20),

                  // Calculation Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _calcRow(
                          isAr ? 'السعر الأساسي ($_selectedShelvesCount رف × $_selectedContractMonths شهر):' : 'Base Storage Fee:',
                          'AED ${quote.rawStorageFee.toStringAsFixed(2)}',
                        ),
                        if (quote.discountSavings > 0)
                          _calcRow(
                            isAr ? 'وفرت مع خصم العقد (${(quote.discountRate * 100).toInt()}%):' : 'Contract Discount Savings:',
                            '- AED ${quote.discountSavings.toStringAsFixed(2)}',
                            color: const Color(0xFF166534),
                          ),
                        if (quote.vasFee > 0)
                          _calcRow(
                            isAr ? 'خدمة التصوير الاحترافي (VAS):' : 'Photography Studio VAS:',
                            'AED ${quote.vasFee.toStringAsFixed(2)}',
                          ),
                        _calcRow(
                          isAr ? 'ضريبة القيمة المضافة (5% VAT):' : 'UAE VAT (5%):',
                          'AED ${quote.vat.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'الإجمالي النهائي المستحق:' : 'Total Subscription Cost:',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'AED ${quote.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.bluePrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  ElevatedButton.icon(
                    onPressed: () {
                      final invId = 'INV-SME-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      final invoice = Invoice(
                        id: invId,
                        number: invId,
                        warehouseName: 'Dubai Central SME Hub',
                        warehouseNameAr: 'مستودع دبي المركزي للأسر المنتجة',
                        date: DateTime.now(),
                        amount: quote.subtotal,
                        vat: quote.vat,
                        type: InvoiceType.rental,
                        metaData: {
                          'shelves': quote.shelfCount,
                          'months': quote.durationMonths,
                          'discount_rate': quote.discountRate,
                          'vas_photography': _includePhotography,
                          'source': 'sme_home_seller_hub',
                        },
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(
                            invoice: invoice,
                            initialMethod: PaymentMethod.fintx,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_clock_outlined, color: Colors.white, size: 18),
                    label: Text(
                      isAr ? 'حجز الأرفف والدفع عبر بوابة Fintx' : 'Subscribe Shelves via Fintx Gateway',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Commercial Model Reference Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'النموذج التجاري الشفاف لـ NXN' : 'Transparent Commercial Model',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  _commercialBullet(
                    icon: Icons.shelves,
                    title: isAr ? 'رسوم التخزين (Standard Shelf)' : 'Storage Fees (Standard Shelf)',
                    desc: isAr ? '100 درهم شهرياً لكل رف قياسي مع خصومات تصل إلى 20% عند العقود السنوية.' : 'AED 100/month with tiered contract savings up to 20%.',
                  ),
                  _commercialBullet(
                    icon: Icons.percent_rounded,
                    title: isAr ? 'رسوم وعمولة المنصة (Platform Fee)' : 'Platform Commission',
                    desc: isAr ? '5% عمولة مبيعات تشمل إدارة المتجر والفوترة والتجهيز.' : '5% commission covering marketplace management & billing.',
                  ),
                  _commercialBullet(
                    icon: Icons.local_shipping_outlined,
                    title: isAr ? 'خدمات التوصيل المحلي (Delivery Tiers)' : 'Domestic Delivery Tiers',
                    desc: isAr ? '15 درهم لليوم التالي، 25 درهم لنفس اليوم، 35 درهم للمناطق النائية.' : 'Next-Day: AED 15 • Express Same-Day: AED 25 • Remote: AED 35.',
                  ),
                  _commercialBullet(
                    icon: Icons.payment_outlined,
                    title: isAr ? 'بوابة الدفع والسحب (Fintx Gateway)' : 'Fintx Payment Gateway & Payouts',
                    desc: isAr ? 'دعم آبل باي والبطاقات ونظام آني للدفع الفوري وتقسيط تابي وتمارا.' : 'Apple Pay, Cards, Aani Instant Transfer, and Tabby/Tamara BNPL.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contractChip(int months, String label, String discount, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedContractMonths = months),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bluePrimary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.bluePrimary : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                discount,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : const Color(0xFF166534),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _commercialBullet({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.bluePrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
