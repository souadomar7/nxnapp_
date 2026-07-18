import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';

class WmsIntegrationPage extends StatefulWidget {
  const WmsIntegrationPage({super.key});

  @override
  State<WmsIntegrationPage> createState() => _WmsIntegrationPageState();
}

class _WmsIntegrationPageState extends State<WmsIntegrationPage> {
  final _wmsUrlCtrl = TextEditingController(text: 'https://api.manhattan-active.ae/wms/v1');
  final _apiKeyCtrl = TextEditingController(text: '************************');
  
  String _selectedProvider = 'Manhattan Active WMS';
  bool _enableRfid = true;
  String _rfidIp = '192.168.10.150';
  bool _isTesting = false;

  final List<String> _syncLogs = [
    '[2026-07-17 19:42:01] WMS Handshake successful. Connected to Manhattan Active.',
    '[2026-07-17 19:45:15] RFID Gate A: Scanned SKU "mock-beans" x12 boxes. Inventory updated.',
    '[2026-07-17 19:50:33] Webhook received from WMS: SKU "mock-earbuds" decremented by 1 (customer pickup).',
  ];

  @override
  void dispose() {
    _wmsUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulateWmsScan() async {
    setState(() => _isTesting = true);
    
    // Simulate API request to the WMS webhook
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Update local database via MarketplaceService
    final service = MarketplaceService();
    final nowStr = DateTime.now().toIso8601String().substring(11, 19);
    
    // Simulate incrementing "Premium Espresso Beans" stock by 10 units
    final invItems = await service.getInventory();
    if (invItems.isNotEmpty) {
      final beans = invItems.firstWhere((e) => e.productId == 'mock-beans', orElse: () => invItems.first);
      debugPrint('WMS Webhook synchronized stock for product: ${beans.productName}');
    }

    if (mounted) {
      setState(() {
        _isTesting = false;
        _syncLogs.insert(
          0,
          '[$nowStr] Webhook simulated: SKU "mock-beans" incremented by 10 units at Dock 4.',
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WMS Webhook payload successfully received & processed!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('WMS & IoT Integration', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bluePrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.settings_input_hdmi_rounded, color: AppColors.bluePrimary, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Link your physical warehouse management software (WMS) and RFID scanning portals directly to the NXN App.',
                      style: TextStyle(fontSize: 13, color: AppColors.bluePrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: WMS Provider Details
            const Text('WMS API INTEGRATION', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProvider,
                    decoration: InputDecoration(
                      labelText: 'WMS Provider / System',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Manhattan Active WMS', child: Text('Manhattan Active WMS')),
                      DropdownMenuItem(value: 'SAP EWM', child: Text('SAP EWM')),
                      DropdownMenuItem(value: 'Oracle WMS Cloud', child: Text('Oracle WMS Cloud')),
                      DropdownMenuItem(value: 'Custom REST API', child: Text('Custom REST API')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProvider = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _wmsUrlCtrl,
                    decoration: InputDecoration(
                      labelText: 'API Endpoint Base URL',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apiKeyCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Authentication Key (Bearer Token / Secret)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: IoT RFID Portal Settings
            const Text('IOT RFID PORTALS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable RFID Gates Autopicking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: const Text('Auto-receive stock passing through dock gates', style: TextStyle(fontSize: 12)),
                    activeThumbColor: AppColors.bluePrimary,
                    value: _enableRfid,
                    onChanged: (val) => setState(() => _enableRfid = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_enableRfid) ...[
                    const Divider(),
                    TextFormField(
                      initialValue: _rfidIp,
                      decoration: InputDecoration(
                        labelText: 'Gate RFID Antenna IP Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.router),
                      ),
                      onChanged: (val) => _rfidIp = val,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Webhook URL / Testing
            const Text('WEBHOOK CONFIGURATION', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Webhook Callback URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  SelectableText(
                    'https://idcagewiltkitmcprrjr.supabase.co/functions/v1/wms-webhook',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isTesting ? null : _simulateWmsScan,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.bluePrimary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isTesting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: AppColors.bluePrimary),
                      label: const Text('Simulate External WMS Scan Event', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: Live Synchronization Log
            const Text('LIVE SYNCHRONIZATION LOGS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark terminal style
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                itemCount: _syncLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _syncLogs[index],
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
