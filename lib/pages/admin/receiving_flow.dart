import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';

class ReceivingFlowPage extends StatefulWidget {
  final Map<String, dynamic>? bookingData; // Real data from Dashboard
  const ReceivingFlowPage({super.key, this.bookingData});

  @override
  State<ReceivingFlowPage> createState() => _ReceivingFlowPageState();
}

class _ReceivingFlowPageState extends State<ReceivingFlowPage> {
  int _currentStep = 0;
  final MarketplaceService _mp = MarketplaceService();
  
  // Data Holder
  late Map<String, dynamic> _data;

  // Inspection State
  bool _boxCountMatch = false;
  bool _noDamageVisible = false;
  bool _isDamaged = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Use passed data or fallback to mock for standalone testing
    if (widget.bookingData != null) {
      _data = widget.bookingData!;
    } else {
        _data = {
        'id': 'MOCK-8818',
        'customer_name': 'Test Customer', // Supabase field might differ, checking schema...
        // Schema from service: 'sme_inbound_requests' has 'gate_pass_code', 'item_count', 'notes', etc.
        // We might not have 'customer_name' directly unless joined. 
        // Let's assume the dashboard passes what it has.
        // If 'raw' was passed, it has DB fields.
        'gate_pass_code': 'MOCK-GP',
        'item_count': 50,
        'notes': 'Test Notes',
      };
    }
  }

  void _nextStep() {
    setState(() => _currentStep++);
  }

  void _simulateScan() async {
    // Simulate camera delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Auto advance to details after "scan"
      _nextStep();
    }
  }
  
  Future<void> _completeReceiving() async {
    setState(() => _isSaving = true);
    
    // Call Service
    final id = _data['id']?.toString() ?? '';
    // If it's a real ID (from Supabase UUID), we update. If mock, we skip or mock.
    if (id.length > 5) { // Simple check for UUID-ish
        // Todo: handle photo upload if _isDamaged. For now passing null.
        await _mp.completeInboundRequest(id, _isDamaged, null);
    } else {
        await Future.delayed(const Duration(seconds: 1)); // Mock save
    }

    if (mounted) {
        setState(() => _isSaving = false);
        _nextStep(); // Go to 'Success' step
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Match dashboard bg
      appBar: AppBar(
        title: const Text('Inbound Processing'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stepper Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepFunc(0, 'Scan', Icons.qr_code_scanner),
                _buildConnector(0),
                _buildStepFunc(1, 'Verify', Icons.playlist_add_check),
                _buildConnector(1),
                _buildStepFunc(2, 'Inspect', Icons.fact_check),
                _buildConnector(2),
                _buildStepFunc(3, 'Done', Icons.check_circle),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bluePrimary, width: 4),
                ),
                child: const Center(child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 60)),
              ),
              const SizedBox(height: 24),
              const Text('Scan Gate Pass QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Align QR code within the frame', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _simulateScan,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Simulate Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        );
      case 1:
        return _buildVerifyStep();
      case 2:
        return _buildInspectStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildVerifyStep() {
    // Extract display values safely
    final id = _data['gate_pass_code'] ?? _data['id'] ?? 'N/A';
    // 'item_count' is likely int
    final itemCount = _data['item_count']?.toString() ?? '0';
    final notes = _data['notes'] ?? 'None';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GP Code #$id', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        // If we had customer name in join, use it, else generic
                         const Text('Verified Entry', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                _kvRow('Expected Items', '$itemCount Boxes'),
                _kvRow('Notes / Manifest', notes),
                // _kvRow('Requested Services', (_bookingData['services'] as List).join(', ')), // Simplification: remove list for now
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.bluePrimary, padding: const EdgeInsets.all(16)),
                    child: const Text('Confirm Details & Proceed', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectStep() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Physical Inspection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _boxCountMatch,
                  onChanged: (v) => setState(() => _boxCountMatch = v!),
                  title: const Text('Box count matches manifest?'),
                ),
                CheckboxListTile(
                  value: _noDamageVisible,
                  onChanged: (v) => setState(() { 
                    _noDamageVisible = v!;
                    if (v) _isDamaged = false;
                  }),
                  title: const Text('No visible damage to packaging?'),
                ),
                const Divider(),
                SwitchListTile(
                  value: _isDamaged,
                  onChanged: _noDamageVisible ? null : (v) => setState(() => _isDamaged = v),
                  activeThumbColor: Colors.red,
                  title: const Text('Report Damage / Issue', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Requires photo evidence'),
                ),
                if (_isDamaged)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                        Text('Tap to Capture Damage Photo'),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _isSaving 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    // Enabled if match AND (no damage OR (damage + photo... well ignoring photo check for now))
                    onPressed: (_boxCountMatch && (_noDamageVisible || _isDamaged)) ? _completeReceiving : null,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.bluePrimary, padding: const EdgeInsets.all(16)),
                    child: const Text('Complete Receiving', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text('Inventory Received Successfully', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Stock is now live for the customer.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Return true to indicate success
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(k, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStepFunc(int stepIndex, String label, IconData icon) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;
    return Column(
      children: [
        CircleAvatar(
          radius: 24, // Larger click/visual target
          backgroundColor: isActive ? AppColors.bluePrimary : Colors.grey[200],
          child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 24),
        ),
        const SizedBox(height: 8), // More breathing room
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.bluePrimary : Colors.grey[600],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            fontSize: 14, // Readable text
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int stepIndex) {
    final isActive = _currentStep > stepIndex;
    return Container(
      width: 50, // Longer connectors for spacing
      height: 4, // Thicker line for visibility
      color: isActive ? AppColors.bluePrimary : Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24), // Better alignment
      decoration: BoxDecoration(
        color: isActive ? AppColors.bluePrimary : Colors.grey[200],
        borderRadius: BorderRadius.circular(2), // Rounded edges
      ),
    );
  }
}
