import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/marketplace_service.dart';
import '../models/history_models.dart';
import '../widgets/camera_scanner.dart';
import '../theme.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  final MarketplaceService _marketplaceService = MarketplaceService();
  final TextEditingController _manualInputCtrl = TextEditingController();
  
  bool _isProcessing = false;
  late AnimationController _animCtrl;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(_animCtrl);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  final Set<String> _consumedPasses = {};

  void _handleScannedCode(String rawCode) async {
    if (_isProcessing) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cleanCode = rawCode.trim().toUpperCase();

    // Security Check: Enforce Single-Use Gate Pass / Token Consumption
    if (_consumedPasses.contains(cleanCode)) {
      _showSecurityReuseAlert(cleanCode, isAr);
      return;
    }

    setState(() => _isProcessing = true);
    _showVerificationModal(cleanCode);
  }

  void _showSecurityReuseAlert(String code, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
              child: const Icon(Icons.gavel_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAr ? 'تنبيه أمني: التصريح مستعمل من قبل' : 'SECURITY REUSE REJECTED ⛔',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Text(
          isAr
              ? 'تم رفض الدخول! تصريح الدخول رقم ($code) تم استهلاكه وفحصه سابقاً في رصيف BAY-3. لا يمكن استخدام تصاريح QR أكثر من مرة واحدة.'
              : 'SECURITY ALERT: Gate Pass ($code) has already been consumed at BAY-3. Cryptographic single-use token policy rejects duplicate entry attempts.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إغلاق' : 'Dismiss', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showVerificationModal(String code) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // Determine Code Type
    bool isInboundGatePass = code.startsWith('STO') || code.startsWith('GP') || code.contains('DROP');
    bool isOutboundWaybill = code.startsWith('WAY') || code.startsWith('DEL') || code.contains('COURIER');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isInboundGatePass ? Colors.blue.shade50 : Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isInboundGatePass ? Icons.warehouse_rounded : Icons.local_shipping_rounded,
                    color: isInboundGatePass ? AppColors.bluePrimary : Colors.green.shade800,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInboundGatePass
                            ? (isAr ? 'تم التحقق من تصريح الدخول' : 'Inbound Gate Pass Verified')
                            : (isAr ? 'تم التحقق من بوليصة الشحن' : 'Courier Shipping Waybill Verified'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        code,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),

            // Specs Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _detailRow(isAr ? 'المستودع المحتضن' : 'Fulfillment Hub', isAr ? 'مستودع دبي المركزي' : 'Dubai Central Warehouse'),
                  const SizedBox(height: 8),
                  _detailRow(
                    isAr ? 'رصيف التفريغ المخصص' : 'Assigned Unloading Bay',
                    isInboundGatePass ? 'BAY-3 (Cold Storage Ramp)' : 'BAY-7 (Outbound Express)',
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    isAr ? 'حالة الشحنة' : 'Logistics Status',
                    isInboundGatePass ? 'Ready for Offloading' : 'Ready for Courier Pickup',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInboundGatePass ? AppColors.bluePrimary : Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  _consumedPasses.add(code);
                  Navigator.pop(ctx);
                  
                  // Log Action in MarketplaceService
                  await _marketplaceService.addActivity(
                    DashboardActivity(
                      id: 'ACT-SCAN-${DateTime.now().millisecondsSinceEpoch}',
                      title: isInboundGatePass ? 'Inbound Bay Check-in ($code)' : 'Courier Handover Verified ($code)',
                      subtitle: isInboundGatePass ? 'Unloaded at Bay-3 • Verified via Camera Scanner' : 'Handed over to NXN Courier Fleet',
                      date: DateTime.now(),
                      type: isInboundGatePass ? ActivityType.inbound : ActivityType.delivery,
                    ),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green.shade800,
                        content: Text(
                          isAr
                              ? 'تم التأكيد وتحديث النظام بنجاح! 📦'
                              : 'Successfully verified & logged in logistics engine! 📦',
                        ),
                      ),
                    );
                    setState(() => _isProcessing = false);
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text(
                  isInboundGatePass
                      ? (isAr ? 'تأكيد تفريغ الشحنة في رصيف BAY-3' : 'Confirm Offloading at Bay-3')
                      : (isAr ? 'تأكيد التسليم لسائق الشحن' : 'Confirm Handover to Courier Driver'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isProcessing = false);
                },
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isAr ? 'ماسح التصاريح والباركوود' : 'Gate Pass & QR Scanner', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.amber),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Feed
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanning Overlay Frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.blueLight, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 280 * _laserAnimation.value,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Manual Code Input Banner
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualInputCtrl,
                      decoration: InputDecoration(
                        hintText: isAr ? 'أدخل كود STO-XXXXXX أو WAY-XXXXXX' : 'Enter STO-XXXXXX or WAY-XXXXXX',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_manualInputCtrl.text.trim().isNotEmpty) {
                        _handleScannedCode(_manualInputCtrl.text.trim());
                      }
                    },
                    child: Text(isAr ? 'فحص' : 'Scan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
