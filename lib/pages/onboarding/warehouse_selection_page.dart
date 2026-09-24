import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../home_shell.dart';

class WarehouseSelectionPage extends StatefulWidget {
  const WarehouseSelectionPage({super.key});

  @override
  State<WarehouseSelectionPage> createState() => _WarehouseSelectionPageState();
}

class _WarehouseSelectionPageState extends State<WarehouseSelectionPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _warehouses = [];
  String? _selectedEmirate;
  String? _selectedWarehouseId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final List<String> _emirates = ['Dubai', 'Abu Dhabi', 'Sharjah', 'Al Ain'];

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _supabase.from('warehouses').select();
      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredWarehouses {
    if (_selectedEmirate == null) return _warehouses;
    return _warehouses.where((w) => w['emirate'] == _selectedEmirate).toList();
  }

  Future<void> _confirmSelection() async {
    if (_selectedWarehouseId == null) return;
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('sme_sellers').upsert({
          'id': user.id,
          'selected_warehouse_id': _selectedWarehouseId,
        });
      }
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          isAr ? 'اختر مستودعك' : 'Choose Your Warehouse',
          style: const TextStyle(color: AppColors.bluePrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.bluePrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading warehouses', style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadWarehouses, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'اختر الإمارة والمستودع الأقرب إليك' : 'Select the emirate and warehouse closest to you',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          // Emirate filter chips
                          SizedBox(
                            height: 38,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                FilterChip(
                                  label: Text(isAr ? 'الكل' : 'All'),
                                  selected: _selectedEmirate == null,
                                  onSelected: (_) => setState(() { _selectedEmirate = null; _selectedWarehouseId = null; }),
                                  selectedColor: AppColors.bluePrimary.withValues(alpha: 0.15),
                                ),
                                const SizedBox(width: 8),
                                ..._emirates.map((e) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(e),
                                    selected: _selectedEmirate == e,
                                    onSelected: (_) => setState(() { _selectedEmirate = e; _selectedWarehouseId = null; }),
                                    selectedColor: AppColors.bluePrimary.withValues(alpha: 0.15),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: _filteredWarehouses.length,
                        itemBuilder: (ctx, i) {
                          final w = _filteredWarehouses[i];
                          final isSelected = _selectedWarehouseId == w['id'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedWarehouseId = w['id']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.bluePrimary.withValues(alpha: 0.07) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.bluePrimary : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.bluePrimary : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.warehouse_rounded,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAr ? (w['name_ar'] ?? w['name']) : w['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isSelected ? AppColors.bluePrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          w['address'] ?? w['emirate'] ?? '',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.shelves, size: 14, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${w['total_shelves']} shelves  •  AED ${w['price_per_shelf']}/shelf/mo',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: AppColors.bluePrimary, size: 24),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedWarehouseId == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  isAr ? 'يمكنك تخطي هذه الخطوة والاختيار لاحقاً' : 'You can skip this step and choose later',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                if (_selectedWarehouseId == null)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeShell()),
                        (route) => false,
                      ),
                      child: Text(isAr ? 'تخطي' : 'Skip for Now'),
                    ),
                  ),
                if (_selectedWarehouseId == null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedWarehouseId == null ? null : (_isSaving ? null : _confirmSelection),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bluePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isAr ? 'تأكيد الاختيار' : 'Confirm Selection',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
