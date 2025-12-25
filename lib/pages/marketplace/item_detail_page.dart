import 'package:flutter/material.dart';
import '../../models/marketplace_models.dart';
import '../../theme.dart';

class ItemDetailPage extends StatelessWidget {
  final SmeInventory item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDamaged = item.status == 'damaged';
    final statusColor = isDamaged ? Colors.red : Colors.green;
    final statusText = isDamaged ? 'Damaged' : 'In Stock';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Full Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  // In real app: Image.network(item.productImage)
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productName ?? 'Unknown Item',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    children: [
                      Icon(isDamaged ? Icons.warning : Icons.check_circle, size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('SKU: ${item.id.substring(0, 8).toUpperCase()}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // 3. Info Grid
            Row(
              children: [
                Expanded(child: _buildInfoCard('Quantity', '${item.quantity}', Icons.numbers)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard('Shelf Location', item.shelfId ?? 'Pending', Icons.shelves)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 4. Damaged Logic
            if (isDamaged) ...[
              const Text('Condition Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detected by Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    const Text('Item box was crushed on bottom left corner during receiving.'),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {}, // View photo
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera, size: 16, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('View Damage Photo', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5. History Log
            const Text('Movement History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildHistoryItem('Received at Warehouse', item.createdAt),
            const Divider(),
            _buildHistoryItem('Placed on Shelf ${item.shelfId}', item.createdAt.add(const Duration(minutes: 45))),
            if (isDamaged) ...[
               const Divider(),
               _buildHistoryItem('Damage Reported', item.createdAt.add(const Duration(minutes: 10)), isAlert: true),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.bluePrimary, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String action, DateTime date, {bool isAlert = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isAlert ? Colors.red[50] : Colors.blue[50],
        child: Icon(isAlert ? Icons.warning : Icons.history, color: isAlert ? Colors.red : AppColors.bluePrimary, size: 18),
      ),
      title: Text(action, style: TextStyle(fontWeight: FontWeight.bold, color: isAlert ? Colors.red : Colors.black)),
      subtitle: Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, "0")}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
