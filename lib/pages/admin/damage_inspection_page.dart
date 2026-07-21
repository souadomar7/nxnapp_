import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/session_provider.dart';

enum ItemCondition { pendingIntake, stored, outForDelivery, damaged }

extension ItemConditionX on ItemCondition {
  String get label => switch (this) {
    ItemCondition.pendingIntake  => 'Pending Intake',
    ItemCondition.stored         => 'Stored',
    ItemCondition.outForDelivery => 'Out for Delivery',
    ItemCondition.damaged        => 'Damaged',
  };
  Color get color => switch (this) {
    ItemCondition.pendingIntake  => Colors.orange,
    ItemCondition.stored         => Colors.green,
    ItemCondition.outForDelivery => Colors.blue,
    ItemCondition.damaged        => Colors.red,
  };
  IconData get icon => switch (this) {
    ItemCondition.pendingIntake  => Icons.hourglass_top_rounded,
    ItemCondition.stored         => Icons.check_circle_rounded,
    ItemCondition.outForDelivery => Icons.local_shipping_rounded,
    ItemCondition.damaged        => Icons.warning_rounded,
  };
}

class DamageInspectionPage extends StatefulWidget {
  const DamageInspectionPage({super.key});
  @override
  State<DamageInspectionPage> createState() => _DamageInspectionPageState();
}

class _DamageInspectionPageState extends State<DamageInspectionPage> {
  final _db = Supabase.instance.client;
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _rentalItems = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRentals();
  }

  Future<void> _fetchRentals() async {
    setState(() => _loading = true);
    try {
      // Fetch active shelf rentals awaiting intake
      final rows = await _db
          .from('shelf_rentals')
          .select('rental_id, user_id, shelf_quantity, warehouse_id, payment_status, condition_status, created_at')
          .order('created_at', ascending: false)
          .limit(50);
      setState(() { _rentalItems = List<Map<String, dynamic>>.from(rows); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _flagDamage(Map<String, dynamic> item) async {
    final rentalId = item['rental_id'];
    // Pick photo from camera
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;

    final file = File(picked.path);
    final userId = _db.auth.currentUser?.id ?? 'admin';
    final photoPath = 'damage/$rentalId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      // Upload photo
      await _db.storage.from('damage-photos').upload(photoPath, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
      final photoUrl = _db.storage.from('damage-photos').getPublicUrl(photoPath);

      // Record damage
      await _db.from('damage_inspection_photos').insert({
        'rental_id': rentalId,
        'photo_url': photoUrl,
        'flagged_by': userId,
        'notes': 'Damage flagged during intake inspection',
        'condition_status': 'DAMAGED',
      });

      // Update rental condition
      await _db.from('shelf_rentals')
          .update({'condition_status': 'DAMAGED'})
          .eq('rental_id', rentalId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Damage recorded. Tenant will be notified.'),
          backgroundColor: Colors.red,
        ));
        _fetchRentals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _updateCondition(String rentalId, ItemCondition condition) async {
    await _db.from('shelf_rentals')
        .update({'condition_status': condition.name.toUpperCase()})
        .eq('rental_id', rentalId);
    _fetchRentals();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionProvider.of(context);
    if (!session.canAccessWms) {
      return const Scaffold(
        body: Center(child: Text('Access Denied — Warehouse Admin only.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('Damage Inspection', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRentals,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _rentalItems.isEmpty
                  ? const Center(child: Text('No active rentals found.'))
                  : RefreshIndicator(
                      onRefresh: _fetchRentals,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rentalItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final item = _rentalItems[i];
                          final condStr = (item['condition_status'] ?? 'PENDING_INTAKE').toString().toUpperCase();
                          final condition = switch (condStr) {
                            'STORED'           => ItemCondition.stored,
                            'OUT_FOR_DELIVERY' => ItemCondition.outForDelivery,
                            'DAMAGED'          => ItemCondition.damaged,
                            _                  => ItemCondition.pendingIntake,
                          };
                          return _RentalInspectionCard(
                            item: item,
                            condition: condition,
                            onFlagDamage: () => _flagDamage(item),
                            onUpdateCondition: (c) => _updateCondition(item['rental_id'].toString(), c),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _RentalInspectionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ItemCondition condition;
  final VoidCallback onFlagDamage;
  final ValueChanged<ItemCondition> onUpdateCondition;

  const _RentalInspectionCard({
    required this.item,
    required this.condition,
    required this.onFlagDamage,
    required this.onUpdateCondition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: condition.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: condition.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(condition.icon, size: 13, color: condition.color),
                      const SizedBox(width: 5),
                      Text(condition.label,
                          style: TextStyle(fontSize: 11, color: condition.color, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('#${item['rental_id'].toString().substring(0, 8)}...',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(label: 'Shelves', value: '${item['shelf_quantity']}'),
                const SizedBox(width: 8),
                _InfoChip(label: 'Warehouse', value: (item['warehouse_id'] ?? '-').toString().toUpperCase()),
                const SizedBox(width: 8),
                _InfoChip(label: 'Payment', value: (item['payment_status'] ?? '-').toString()),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFlagDamage,
                    icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.red),
                    label: const Text('Flag Damage', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<ItemCondition>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: onUpdateCondition,
                  itemBuilder: (_) => ItemCondition.values
                      .map((c) => PopupMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(c.icon, size: 16, color: c.color),
                                const SizedBox(width: 8),
                                Text(c.label),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
