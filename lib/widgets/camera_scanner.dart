import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';

class CameraScanner extends StatefulWidget {
  final String title;
  const CameraScanner({super.key, this.title = 'Scan Barcode'});

  @override
  State<CameraScanner> createState() => _CameraScannerState();
}

class _CameraScannerState extends State<CameraScanner> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanArea = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewport
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  _isScanned = true;
                  Navigator.pop(context, code);
                  break;
                }
              }
            },
          ),

          // 2. Custom Viewfinder Mask (Semi-transparent black overlay with transparent center box)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: scanArea,
                    width: scanArea,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Viewfinder Focus Box (Neon Blue Corners)
          Align(
            alignment: Alignment.center,
            child: Container(
              height: scanArea,
              width: scanArea,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Beautiful Neon Blue Corner Borders
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.bluePrimary, width: 4),
                          left: BorderSide(color: AppColors.bluePrimary, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.bluePrimary, width: 4),
                          right: BorderSide(color: AppColors.bluePrimary, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.bluePrimary, width: 4),
                          left: BorderSide(color: AppColors.bluePrimary, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.bluePrimary, width: 4),
                          right: BorderSide(color: AppColors.bluePrimary, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
                      ),
                    ),
                  ),

                  // Scanning Line Animation placeholder
                  const _ScanLineAnimation(),
                ],
              ),
            ),
          ),

          // 4. Header Bar (Scan Title + Flash toggle + Back arrow)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isTorchOn ? Colors.yellow : Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                      _controller.toggleTorch();
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Instruction text
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Align barcode or QR code inside the viewfinder frame to scan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLineAnimation extends StatefulWidget {
  const _ScanLineAnimation();

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _offsetAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Align(
          alignment: Alignment(0, (_offsetAnimation.value * 2) - 1),
          child: Container(
            height: 2.5,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.bluePrimary.withValues(alpha: 0.0),
                  AppColors.bluePrimary,
                  AppColors.bluePrimary.withValues(alpha: 0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.bluePrimary.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
