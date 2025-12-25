import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Ensure this is in pubspec, otherwise use basic image or container

class DropoffBookingPage extends StatefulWidget {
  const DropoffBookingPage({super.key});

  @override
  State<DropoffBookingPage> createState() => _DropoffBookingPageState();
}

class _DropoffBookingPageState extends State<DropoffBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  
  bool _addLabor = false;
  int _workerCount = 1;
  bool _detailedInspection = false;

  bool _isLoading = false;
  final MarketplaceService _service = MarketplaceService();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      if (!mounted) return;
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final count = int.parse(_countController.text);
      await _service.createDropOffRequest(
        _selectedDate,
        count,
        _notesController.text,
        laborCount: _addLabor ? _workerCount : 0,
        inspection: _detailedInspection,
        // warehouseId: // Would fetch selected warehouse from context or state
      );
      
      if (mounted) {
        // Show Success & Gate Pass
        _showGatePassDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGatePassDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Booking Confirmed')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text('Your drop-off slot is reserved. Below is your Digital Gate Pass.'),
               const SizedBox(height: 16),
               Container(
                 padding: const EdgeInsets.all(16),
                 color: Colors.white,
                 child: QrImageView(
                   data: 'GP-982374-DXB',
                   version: QrVersions.auto,
                   size: 200.0,
                 ),
               ),
               const SizedBox(height: 8),
               const Text('GP-982374-DXB', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close Page
              }, 
              child: const Text('Save to Wallet')
            ), 
            ElevatedButton(
              onPressed: () {
                 Navigator.pop(context); // Close dialog
                 Navigator.pop(context); // Close Page
              }, 
              child: const Text('Done')
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bookDropoffTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.bluePrimary,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               _buildSectionHeader('1. Schedule'),
               ListTile(
                 title: Text(
                   '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day} at ${TimeOfDay.fromDateTime(_selectedDate).format(context)}',
                   style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                 subtitle: const Text('Tap to change slot'),
                 trailing: const Icon(Icons.calendar_today, color: AppColors.bluePrimary),
                 tileColor: Colors.grey[100],
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 onTap: _pickDate,
               ),
               const SizedBox(height: 24),
               
               _buildSectionHeader('2. Shipment Details'),
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.approxItemCountLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                validator: (val) {
                   if (val == null || val.isEmpty) return AppLocalizations.of(context)!.requiredError;
                   if (int.tryParse(val) == null) return AppLocalizations.of(context)!.invalidNumberError;
                   return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.notesFragileLabel,
                  border: const OutlineInputBorder(),
                   prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('3. Add-ons'),
               SwitchListTile(
                title: const Text('Request Unloading Workers'),
                subtitle: const Text('AED 50/worker'),
                value: _addLabor,
                activeThumbColor: AppColors.bluePrimary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _addLabor = val),
              ),
              if (_addLabor)
                  Row(
                    children: [
                      const Text('Count: '),
                      IconButton(onPressed: () => setState(() => _workerCount = (_workerCount > 1 ? _workerCount - 1 : 1)), icon: const Icon(Icons.remove)),
                      Text('$_workerCount'),
                      IconButton(onPressed: () => setState(() => _workerCount++), icon: const Icon(Icons.add)),
                    ],
                  ),
               const Divider(),
               SwitchListTile(
                title: const Text('Detailed Inspection'),
                subtitle: const Text('Verify items inside boxes (Extra Fee)'),
                value: _detailedInspection,
                activeThumbColor: AppColors.bluePrimary,
                 contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _detailedInspection = val),
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text(AppLocalizations.of(context)!.submitDropoffButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}
