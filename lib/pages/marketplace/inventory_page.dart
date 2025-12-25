import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart';
import '../../l10n/app_localizations.dart';
import 'item_detail_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final MarketplaceService _service = MarketplaceService();
  late Future<List<SmeInventory>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() {
    setState(() {
      _inventoryFuture = _service.getInventory();
    });
  }

  // Filters
  String _filterBranch = 'All';
  String _filterStatus = 'All';
  String _searchQuery = '';  

  List<SmeInventory> _filterList(List<SmeInventory> items) {
     return items.where((i) {
       // Search
       final matchesSearch = _searchQuery.isEmpty || 
                             (i.productName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                             (i.shelfId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
       
       // Status Filter
       final matchesStatus = _filterStatus == 'All' || 
                             (_filterStatus == 'Good' && i.status == 'in_stock') ||
                             (_filterStatus == 'Damaged' && i.status == 'damaged');

       // Branch Filter (Mock based on Shelf ID convention or just pass all for now if no branch info)
       // Let's assume AUH, DXB prefixes for shelf ID in future. For now, just 'All' passes.
       // Actually, let's map Shelf ID Prefix to Branch manually for demo if needed, but mostly 'All'.
       final matchesBranch = _filterBranch == 'All'; // Placeholder until branch logic is cleaner

       return matchesSearch && matchesStatus && matchesBranch;
     }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myInventoryTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search items, SKU, or shelf...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[50], 
      body: FutureBuilder<List<SmeInventory>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
             return Center(child: Text(AppLocalizations.of(context)!.noInventory));
          }

          final allItems = snapshot.data!;
          final items = _filterList(allItems);

          return Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    _buildFilterChip('All', _filterStatus, (v) => _filterStatus = v),
                    const SizedBox(width: 8),
                    _buildFilterChip('Good', _filterStatus, (v) => _filterStatus = v),
                    const SizedBox(width: 8),
                    _buildFilterChip('Damaged', _filterStatus, (v) => _filterStatus = v),
                    const SizedBox(width: 16),
                    const Text('Branch: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    _buildFilterChip('All', _filterBranch, (v) => _filterBranch = v),
                    // _buildFilterChip('Abu Dhabi', _filterBranch, (v) => _filterBranch = v), // Unlock when data ready
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Navigate to Detail
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailPage(item: item)));
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                          title: Text(item.productName ?? AppLocalizations.of(context)!.unknownProduct, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text('${AppLocalizations.of(context)!.qtyLabel(item.quantity)}  •  ${AppLocalizations.of(context)!.shelfLabel(item.shelfId ?? "Pending")}'),
                               // Text(AppLocalizations.of(context)!.statusLabel(item.status), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                          trailing: _buildStockIndicator(item.quantity, item.status == 'damaged'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentVal, Function(String) onSelect) {
    final isSelected = currentVal == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => onSelect(label));
      },
      selectedColor: AppColors.bluePrimary.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: isSelected ? AppColors.bluePrimary : Colors.black),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildStockIndicator(int quantity, bool isDamaged) {
    if (isDamaged) {
       return _statusBadge(Colors.red, 'Damaged');
    }
    
    if (quantity == 0) {
      return _statusBadge(Colors.red, AppLocalizations.of(context)!.itemOutOfStock);
    } else if (quantity < 10) {
      return _statusBadge(Colors.orange, 'Low Stock');
    } else {
      return _statusBadge(Colors.green, AppLocalizations.of(context)!.itemInStock);
    }
  }

  Widget _statusBadge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
