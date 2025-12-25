import 'package:flutter/material.dart';
import '../../data/demo_warehouses.dart'; // Using demo data for now
import '../../models/warehouse.dart';
import '../../theme.dart';
import 'shelf_config_page.dart';

class BookingMapPage extends StatelessWidget {
  const BookingMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.bluePrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.bluePrimary),
      ),
      body: Column(
        children: [
          // Filter/Header Section
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
             child: Row(
               children: [
                 const Icon(Icons.map, color: Colors.grey),
                 const SizedBox(width: 8),
                 Text(
                   '4 Warehouses Available',
                   style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                 ),
                 const Spacer(),
                 TextButton.icon(
                   onPressed: () {
                     // Toggle Map View (Future)
                   }, 
                   icon: const Icon(Icons.filter_list),
                   label: const Text('Filter'),
                 )
               ],
             ),
          ),
          
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: demoWarehouses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final warehouse = demoWarehouses[index];
                return _WarehouseCard(warehouse: warehouse);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;

  const _WarehouseCard({required this.warehouse});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShelfConfigPage(warehouse: warehouse),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Placeholder (Gradient for now)
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bluePrimary, AppColors.bluePrimary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                   Center(
                     child: Icon(Icons.warehouse, size: 60, color: Colors.white.withValues(alpha: 0.5)),
                   ),
                   Positioned(
                     bottom: 12,
                     left: 12,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                       decoration: BoxDecoration(
                         color: Colors.black54,
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.location_on, color: Colors.white, size: 14),
                           const SizedBox(width: 4),
                           Text(warehouse.emirate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ),
                   ),
                   if (warehouse.is24h)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: Colors.green,
                           borderRadius: BorderRadius.circular(4),
                         ),
                        child: const Text('24/7 Access', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.bluePrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                     children: [
                       Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[600]),
                       const SizedBox(width: 4),
                       Text('${warehouse.shelvesAvailable} Shelves Available', style: TextStyle(color: Colors.grey[700])),
                     ],
                  ),
                  const SizedBox(height: 12),
                  // Amenities
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: warehouse.amenities.take(3).map((a) => Chip(
                      label: Text(a, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.grey[100],
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AED ${warehouse.pricePerShelf.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.orangeAccent)),
                          const Text('/shelf /month', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShelfConfigPage(warehouse: warehouse),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bluePrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Book Now', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
