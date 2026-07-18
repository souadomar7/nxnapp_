import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/camera_scanner.dart';

class PutAwayPage extends StatefulWidget {
  const PutAwayPage({super.key});

  @override
  State<PutAwayPage> createState() => _PutAwayPageState();
}

class _PutAwayPageState extends State<PutAwayPage> {
  int _step = 0; // 0 = Scan Item, 1 = Scan Shelf, 2 = Success
  String? _scannedItem;
  String? _scannedShelf;

  void _scanItemWithCamera() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScanner(title: 'Scan Item Label')),
    );
    if (scannedCode != null && mounted) {
      setState(() {
        _scannedItem = scannedCode;
        _step = 1;
      });
    }
  }

  void _scanShelfWithCamera() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScanner(title: 'Scan Shelf QR')),
    );
    if (scannedCode != null && mounted) {
      setState(() {
        _scannedShelf = scannedCode;
        _step = 2; // Finish
      });
    }
  }

  void _scanItem() {
    // Mock Scan
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _scannedItem = "Box #8818 - Electronics";
          _step = 1;
        });
      }
    });
  }

  void _scanShelf() {
    // Mock Scan
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _scannedShelf = "Shelf A-10-2";
          _step = 2; // Finish
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _step = 0;
      _scannedItem = null;
      _scannedShelf = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Put-Away & Shelf Link'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status Bar
            Row(
              children: [
                _statusCircle(0, 'Scan Item'),
                const Expanded(child: Divider()),
                _statusCircle(1, 'Scan Shelf'),
                const Expanded(child: Divider()),
                _statusCircle(2, 'Linked'),
              ],
            ),
            const SizedBox(height: 48),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_step == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 100, color: AppColors.bluePrimary),
          const SizedBox(height: 24),
          const Text('Step 1: Scan Item Barcode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Scan the box inventory label', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _scanItemWithCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan with Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluePrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _scanItem,
            icon: const Icon(Icons.videogame_asset_outlined),
            label: const Text('Simulate Scan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.bluePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    } else if (_step == 1) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Text('Item Scanned: $_scannedItem', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 32),
          const Icon(Icons.shelves, size: 100, color: Colors.orange),
          const SizedBox(height: 24),
          const Text('Step 2: Scan Shelf Label', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Walk to the assigned location and scan shelf QR', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _scanShelfWithCamera,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Scan with Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _scanShelf,
            icon: const Icon(Icons.videogame_asset_outlined),
            label: const Text('Simulate Scan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          const SizedBox(height: 24),
          const Text('Success! Item Linked.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('$_scannedItem', style: const TextStyle(fontSize: 18)),
          const Icon(Icons.arrow_downward, size: 24, color: Colors.grey),
          Text('$_scannedShelf', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _reset,
            child: const Text('Process Next Item'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done / Return to Dashboard'),
          ),
        ],
      );
    }
  }

  Widget _statusCircle(int step, String label) {
    final isActive = _step >= step;
    final isCurrent = _step == step;
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isCurrent ? AppColors.bluePrimary : (isActive ? Colors.green : Colors.grey[200]),
          child: Icon(isActive ? Icons.check : Icons.circle, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.bluePrimary : Colors.grey[600],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          )
        )
      ],
    );
  }
}
