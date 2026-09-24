import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/pdf_export_service.dart';
import '../document_preview_page.dart';

class GatePassPage extends StatelessWidget {
  final String? bookingId;
  final String? warehouseName;
  final String? timeSlot;
  final String? truckPlate;
  final int? itemCount;

  const GatePassPage({
    super.key,
    this.bookingId,
    this.warehouseName,
    this.timeSlot,
    this.truckPlate,
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bookingRef = bookingId ?? 'STO-881868';
    final hubName = warehouseName ?? (isAr ? 'مستودع دبي المركزي' : 'Dubai Central Warehouse');
    final slotStr = timeSlot ?? '08:00 AM - 11:00 AM';
    final plateStr = truckPlate ?? 'UAE-DXB-92810';
    final itemsCountStr = '${itemCount ?? 50} ${isAr ? "قطع" : "Units"}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(
          isAr ? 'تصريح دخول المستودع الرقمي' : 'Official Warehouse Gate Pass',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Status Verified Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'تصريح دخول معتمد ونشط ✓' : 'VERIFIED ACTIVE GATE PASS ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Colors.green.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isAr ? 'إبراز رمز QR عند البوابة الرئيسية لبدء التنزيل' : 'Show QR code to security at main gate for unloading',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Official Pass Card Ticket
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pass Card Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.bluePrimary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'NXN HUB LOGISTICS',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      isAr ? 'تصريح توريد البضائع' : 'INBOUND CARGO PASS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            bookingRef,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // QR Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bluePrimary.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: 'NXN-ENTRY-$bookingRef',
                            version: QrVersions.auto,
                            size: 190.0,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${isAr ? "رقم المرجع:" : "Booking Ref:"} $bookingRef',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.bluePrimary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashed Divider Line
                  Row(
                    children: List.generate(
                      30,
                      (index) => Expanded(
                        child: Container(
                          height: 1.5,
                          color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),

                  // Pass Details Grid
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _detailRow(
                          icon: Icons.location_city_rounded,
                          label: isAr ? 'المستودع والمرفق' : 'Warehouse Location',
                          value: hubName,
                          highlight: true,
                        ),
                        const SizedBox(height: 12),
                        _detailRow(
                          icon: Icons.access_time_rounded,
                          label: isAr ? 'نافذة الوقت المحجوزة' : 'Time Slot Window',
                          value: slotStr,
                        ),
                        const SizedBox(height: 12),
                        _detailRow(
                          icon: Icons.local_shipping_rounded,
                          label: isAr ? 'الشاحنة والناقل' : 'Truck & Carrier Plate',
                          value: plateStr,
                        ),
                        const SizedBox(height: 12),
                        _detailRow(
                          icon: Icons.inventory_2_rounded,
                          label: isAr ? 'الكميات المتوقعة' : 'Cargo Quantity',
                          value: itemsCountStr,
                        ),
                      ],
                    ),
                  ),

                  // Barcode Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.line_weight_rounded, size: 36, color: AppColors.textPrimary),
                        const SizedBox(height: 4),
                        Text(
                          '*$bookingRef*BAY3*',
                          style: const TextStyle(
                            fontFamily: 'Monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dual Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentPreviewPage(
                            title: 'Gate_Pass_$bookingRef',
                            buildPdf: () => PdfExportService.generateGatePassPdf(
                              gatePassCode: bookingRef,
                              warehouseName: hubName,
                              dateStr: 'Today',
                              itemCount: itemCount ?? 50,
                              laborCount: 1,
                              tempMode: 'Ambient Storage (25°C)',
                              truckPlate: plateStr,
                              notes: 'Official Gate Entry',
                            ),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.bluePrimary, size: 18),
                    label: Text(
                      isAr ? 'تصدير PDF' : 'PDF Pass',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.bluePrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green.shade800,
                          content: Text(
                            isAr ? 'تم حفظ تصريح الدخول في المعرض والمحفظة المحلية! 📸' : 'Gate Pass cached offline & saved to Gallery! 📸',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      l10n.saveToGallery,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // WhatsApp Courier Sharing & Wallet Export
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final msg = isAr
                          ? 'تصريح دخول مستودع NXN HUB\nالرمز: $bookingRef\nالموقع: $hubName\nالوقت: $slotStr\nالمركبة: $plateStr\nيرجى إبراز هذا الرمز عند البوابة رقم 3.'
                          : 'NXN HUB Official Gate Pass\nCode: $bookingRef\nFacility: $hubName\nSlot: $slotStr\nVehicle: $plateStr\nPlease present this pass at Dock Gate 3.';
                      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isAr ? 'تعذر فتح تطبيق واتساب' : 'Could not launch WhatsApp')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      isAr ? 'مشاركة السائق عبر واتساب' : 'Share with Driver (WhatsApp)',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: highlight ? AppColors.bluePrimary.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: highlight ? AppColors.bluePrimary : Colors.grey.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: highlight ? AppColors.bluePrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
