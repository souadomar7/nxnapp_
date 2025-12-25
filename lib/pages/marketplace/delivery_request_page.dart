import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart';
import '../operations/tracking_page.dart';


class DeliveryRequestPage extends StatefulWidget {
  const DeliveryRequestPage({super.key});

  @override
  State<DeliveryRequestPage> createState() => _DeliveryRequestPageState();
}

class _DeliveryRequestPageState extends State<DeliveryRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  // Address might be less relevant if we select City/Country, but user might need specific street address. 
  // Requirement says "Details for Recipient Name and Phone Number". And "Select City/Country".
  // Usually address line is still needed for delivery. I will keep it but make it generic.
  final _addressLineController = TextEditingController();

  String? _selectedProductId;
  bool _isInternational = false;
  String _serviceLevel = 'Standard'; // Express, Standard, Economy
  String? _selectedLocation; // City or Country
  String _carrier = 'NXN Logistics';

  bool _isLoading = false;
  final MarketplaceService _service = MarketplaceService();
  List<SmeInventory> _inventory = [];

  // Mock Data
  final List<String> _cities = ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Al Ain'];
  final List<String> _countries = ['Saudi Arabia', 'Oman', 'Kuwait', 'Bahrain', 'United Kingdom', 'USA'];
  final List<String> _carriers = ['NXN Logistics', 'EMX', 'Aramex', 'DHL'];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final items = await _service.getInventory();
      if (mounted) setState(() => _inventory = items.where((i) => i.quantity > 0).toList());
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an item')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Mock API Call
      await Future.delayed(const Duration(seconds: 1));
      
      await _service.createDeliveryRequest(
        _nameController.text,
        '${_isInternational ? "Intl" : "Dom"} - $_selectedLocation - ${_addressLineController.text}',
        '$_carrier ($_serviceLevel)',
      );
      
      if (mounted) {
        // Navigator.pop(context); // Remove pop
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrackingPage(trackingId: 'TRK-NEW-001')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Options'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF9FAFB), // Light gray bg
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Item Selection
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProductId,
                      hint: const Text('Choose Item from Inventory'),
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: _inventory.map((item) {
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.productName ?? "Item"} (${item.quantity})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedProductId = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Delivery Mode
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildModeButton('Domestic', !_isInternational)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildModeButton('International', _isInternational)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Service Level
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildServiceLevelCard('Express', '1-2 Days')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildServiceLevelCard('Standard', '3-5 Days')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildServiceLevelCard('Economy', '5-7 Days')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Details (Location, Carrier, Recipient)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isInternational ? 'Destination Country' : 'Destination City', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_isInternational),
                      initialValue: _selectedLocation,
                      hint: Text(_isInternational ? 'Select Country' : 'Select City'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: (_isInternational ? _countries : _cities).map((loc) {
                        return DropdownMenuItem(value: loc, child: Text(loc));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLocation = val),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Shipping Company', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                     DropdownButtonFormField<String>(
                      initialValue: _carrier,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _carriers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _carrier = val!),
                    ),
                    const SizedBox(height: 16),

                    const Text('Recipient Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Recipient Name', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                     TextFormField(
                      controller: _addressLineController,
                      decoration: const InputDecoration(labelText: 'Street Address (Optional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Confirm Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  Widget _buildModeButton(String text, bool isSelected) {
    return InkWell(
      onTap: () => setState(() {
        _isInternational = (text == 'International');
        _selectedLocation = null; // Reset location
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bluePrimary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.bluePrimary : Colors.grey[300]!),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceLevelCard(String level, String time) {
    final isSelected = _serviceLevel == level;
    return InkWell(
      onTap: () => setState(() => _serviceLevel = level),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bluePrimary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.bluePrimary : Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(level, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppColors.bluePrimary : Colors.black)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
