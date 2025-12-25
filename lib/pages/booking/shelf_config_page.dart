import 'package:flutter/material.dart';
import '../../models/warehouse.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
 // Future use
import '../home_shell.dart'; // For after booking

class ShelfConfigPage extends StatefulWidget {
  final Warehouse warehouse;

  const ShelfConfigPage({super.key, required this.warehouse});

  @override
  State<ShelfConfigPage> createState() => _ShelfConfigPageState();
}

class _ShelfConfigPageState extends State<ShelfConfigPage> {
  int _shelfCount = 1;
  double _durationMonths = 1.0;
  
  bool _addLabor = false;
  int _workerCount = 1;
  
  bool _detailedInspection = false;

  // Pricing constants (Mock)
  final double _laborFeePerWorker = 50.0;
  final double _inspectionFee = 200.0; // Flat fee for detailed inspection

  // Fixed rate 100 AED per shelf/month implied by data, but let's keep using widget.warehouse.pricePerShelf for robustness
  double get _totalRentalPrice {
    return _shelfCount * widget.warehouse.pricePerShelf * _durationMonths;
  }

  double get _oneTimeFees {
    double total = 0;
    if (_addLabor) {
      total += _workerCount * _laborFeePerWorker;
    }
    if (_detailedInspection) {
      total += _inspectionFee;
    }
    return total;
  }

  double get _grandTotal => _totalRentalPrice + _oneTimeFees;

  void _handlePayment() {
    // Mock Payment
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Trigger subscription creation in background or before showing this?
        // Ideally we show a loading indicator first, but for simplicity we assume success.
        // Let's actually call the service here.
        final MarketplaceService service = MarketplaceService();
        service.createSubscription(
          widget.warehouse.id, 
          _shelfCount, 
          _durationMonths.round(), 
          _grandTotal
        ); // Fire and forgot or await if we convert this to StatefulWidget builder logic

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You have booked $_shelfCount shelves at ${widget.warehouse.name}.'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bluePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    // Navigate to Dashboard
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeShell()),
                      (route) => false,
                    );
                  },
                  child: const Text('Go to Dashboard', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.warehouse.name),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.bluePrimary,
        elevation: 0,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shelf Configuration
                  _buildSectionTitle('1. Shelf Configuration'),
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text('Shelves Needed', style: Theme.of(context).textTheme.titleMedium),
                             Text('$_shelfCount', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
                          ],
                        ),
                        Slider(
                          value: _shelfCount.toDouble(),
                          min: 1,
                          max: widget.warehouse.shelvesAvailable.toDouble(),
                          divisions: (widget.warehouse.shelvesAvailable - 1) < 1 ? 1 : (widget.warehouse.shelvesAvailable - 1),
                          activeColor: AppColors.bluePrimary,
                          label: '$_shelfCount',
                          onChanged: (val) => setState(() => _shelfCount = val.round()),
                        ),
                        const Text('1 Shelf = 2m x 1m x 2m', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Duration
                  _buildSectionTitle('2. Duration'),
                  _buildCard(
                    child: Column(
                      children: [
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text('Rental Period', style: Theme.of(context).textTheme.titleMedium),
                             Text('${_durationMonths.round()} Months', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _durationMonths,
                          min: 1,
                          max: 12,
                          divisions: 11,
                          activeColor: AppColors.orangeAccent,
                          label: '${_durationMonths.round()} Months',
                          onChanged: (val) => setState(() => _durationMonths = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add-ons
                  _buildSectionTitle('3. Add-ons & Services'),
                  _buildCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Need Unloading Help?'),
                          subtitle: const Text('Workers will unload your goods.'),
                          value: _addLabor,
                          activeThumbColor: AppColors.bluePrimary,
                          onChanged: (val) => setState(() => _addLabor = val),
                        ),
                        if (_addLabor)
                           Padding(
                             padding: const EdgeInsets.only(left: 16, bottom: 8),
                             child: Row(
                               children: [
                                 const Text('Workers: '),
                                 IconButton(onPressed: () => setState(() => _workerCount = (_workerCount > 1 ? _workerCount - 1 : 1)), icon: const Icon(Icons.remove_circle_outline)),
                                 Text('$_workerCount'),
                                 IconButton(onPressed: () => setState(() => _workerCount++), icon: const Icon(Icons.add_circle_outline)),
                                 const Spacer(),
                                 Text('+ AED ${(_workerCount * _laborFeePerWorker).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                               ],
                             ),
                           ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Detailed Inspection'),
                          subtitle: const Text('Verify individual items inside boxes.'),
                          value: _detailedInspection,
                          activeThumbColor: AppColors.bluePrimary,
                          onChanged: (val) => setState(() => _detailedInspection = val),
                        ),
                         if (_detailedInspection)
                           Align(alignment: Alignment.centerRight, child: Text('+ AED $_inspectionFee', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Estimate', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text('AED ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.bluePrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bluePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Proceed to Payment', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'No hidden fees. Cancel anytime.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
