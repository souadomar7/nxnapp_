import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_models.dart';
import '../../l10n/app_localizations.dart';
import 'item_detail_page.dart';
import '../../widgets/brand_logo.dart';

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
      backgroundColor: const Color(0xFFF3F6FB), // Light Grey-Blue background
      body: FutureBuilder<List<SmeInventory>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          // Data handling
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final allItems = snapshot.data ?? [];
          final items = _filterList(allItems);

          return CustomScrollView(
            slivers: [
              // 1. Premium Header
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.bluePrimary,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: const BrandLogo(height: 32),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.myInventoryTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.inventorySubtitle(items.length),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchInventoryHint,
                        prefixIcon: const Icon(Icons.search, color: AppColors.bluePrimary),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.bluePrimary, width: 2)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),
              ),

              // 2. Filters & Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F6FB),
                  ),
                  child: Column(
                    children: [
                       // Filters
                       SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            _buildFilterSection(
                              AppLocalizations.of(context)!.statusFilter,
                              ['All', 'Good', 'Damaged'],
                              _filterStatus,
                              (v) => _filterStatus = v,
                              context
                            ),
                            const SizedBox(width: 20),
                            Container(width: 1, height: 24, color: Colors.grey[300]),
                            const SizedBox(width: 20),
                            _buildFilterSection(
                                AppLocalizations.of(context)!.branchFilter,
                                ['All'], // Mock branches
                                _filterBranch,
                                (v) => _filterBranch = v,
                                context
                            ),
                          ],
                        ),
                      ),
                      
                      if (isLoading)
                        const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())
                      else if (hasError)
                         Padding(padding: const EdgeInsets.all(40), child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString())))
                      else if (items.isEmpty)
                         Padding(
                           padding: const EdgeInsets.all(40),
                           child: Column(
                             children: [
                               Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                               const SizedBox(height: 16),
                               Text(AppLocalizations.of(context)!.noInventory, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                             ],
                           ),
                         )
                      else
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildInventoryCard(context, item);
                          },
                        ),
                        
                       const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String current, Function(String) onSelect, BuildContext context) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
        const SizedBox(width: 8),
        ...options.map((opt) {
          final isSelected = current == opt;
          String label = opt;
          if (opt == 'All') {
            label = AppLocalizations.of(context)!.all;
          } else if (opt == 'Good') {
            label = AppLocalizations.of(context)!.goodStatus;
          } else if (opt == 'Damaged') {
            label = AppLocalizations.of(context)!.damagedStatus;
          }
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => onSelect(opt)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.bluePrimary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.bluePrimary : Colors.grey[300]!),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.bluePrimary.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInventoryCard(BuildContext context, SmeInventory item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6F2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailPage(item: item)));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon / Image Placeholder
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.bluePrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.bluePrimary, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? AppLocalizations.of(context)!.unknownProduct,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.shelves, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.shelfLabel(item.shelfId ?? "Pending"), 
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.layers_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.qtyLabel(item.quantity),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                _buildStockIndicator(item.quantity, item.status == 'damaged'),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator(int quantity, bool isDamaged) {
    if (isDamaged) {
       return _statusBadge(Colors.red, AppLocalizations.of(context)!.damagedStatus);
    }
    
    if (quantity == 0) {
      return _statusBadge(Colors.red, AppLocalizations.of(context)!.itemOutOfStock);
    } else if (quantity < 10) {
      return _statusBadge(Colors.orange, AppLocalizations.of(context)!.lowStock);
    } else {
      return _statusBadge(Colors.green, AppLocalizations.of(context)!.itemInStock);
    }
  }

  Widget _statusBadge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
