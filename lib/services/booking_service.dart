import 'package:supabase_flutter/supabase_flutter.dart';

/// Canonical booking business logic — PRD §3 billing + dynamic shelf availability.
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final _db = Supabase.instance.client;

  static const double pricePerShelfPerMonth = 100.0;
  static const double workerFlatFee = 50.0;
  static const double platformFeeRate = 0.05;
  static const double vatRate = 0.05;

  BookingBill calculateBill({required int shelves, required int months, required bool workerRequested}) {
    final double base = shelves * pricePerShelfPerMonth * months;
    final double worker = workerRequested ? workerFlatFee : 0.0;
    final double subtotal = base + worker;
    final double platformFee = subtotal * platformFeeRate;
    final double vat = (subtotal + platformFee) * vatRate;
    return BookingBill(baseRent: base, workerFee: worker, platformFee: platformFee, vat: vat, total: subtotal + platformFee + vat);
  }

  Future<int> getAvailableShelfCount(String warehouseId) async {
    try {
      final row = await _db.from('warehouses')
          .select('max_shelf_capacity, current_used_shelves')
          .eq('warehouse_id', warehouseId).single();
      final int max = (row['max_shelf_capacity'] as num?)?.toInt() ?? 0;
      final int used = (row['current_used_shelves'] as num?)?.toInt() ?? 0;
      return (max - used).clamp(0, max);
    } catch (_) { return 50; }
  }

  Future<List<WarehouseAvailability>> getWarehousesWithAvailability() async {
    try {
      final rows = await _db.from('warehouses')
          .select('warehouse_id, location_name, max_shelf_capacity, current_used_shelves');
      return (rows as List).map((r) {
        final int max = (r['max_shelf_capacity'] as num?)?.toInt() ?? 0;
        final int used = (r['current_used_shelves'] as num?)?.toInt() ?? 0;
        return WarehouseAvailability(
          warehouseId: r['warehouse_id'].toString(), locationName: r['location_name'].toString(),
          maxCapacity: max, usedShelves: used, availableShelves: (max - used).clamp(0, max));
      }).toList();
    } catch (_) {
      return [
        const WarehouseAvailability(warehouseId: 'dxb', locationName: 'Dubai', maxCapacity: 200, usedShelves: 0, availableShelves: 200),
        const WarehouseAvailability(warehouseId: 'auh', locationName: 'Abu Dhabi', maxCapacity: 150, usedShelves: 0, availableShelves: 150),
        const WarehouseAvailability(warehouseId: 'shj', locationName: 'Sharjah', maxCapacity: 100, usedShelves: 0, availableShelves: 100),
        const WarehouseAvailability(warehouseId: 'aln', locationName: 'Al Ain', maxCapacity: 80, usedShelves: 0, availableShelves: 80),
      ];
    }
  }

  Future<String?> createRental({required String warehouseId, required String userId,
      required int shelfQuantity, required int months, required bool requiresWorkers,
      required double totalPaid, DateTime? prepTimeSlot}) async {
    try {
      final bill = calculateBill(shelves: shelfQuantity, months: months, workerRequested: requiresWorkers);
      final result = await _db.from('shelf_rentals').insert({
        'user_id': userId, 'warehouse_id': warehouseId, 'shelf_quantity': shelfQuantity,
        'base_cost': bill.baseRent, 'requires_workers': requiresWorkers, 'worker_fee': bill.workerFee,
        'prep_time_slot': prepTimeSlot?.toIso8601String(), 'total_paid': totalPaid, 'payment_status': 'PENDING',
      }).select('rental_id').single();
      return result['rental_id']?.toString();
    } catch (_) { return null; }
  }
}

class BookingBill {
  final double baseRent, workerFee, platformFee, vat, total;
  const BookingBill({required this.baseRent, required this.workerFee, required this.platformFee, required this.vat, required this.total});
}

class WarehouseAvailability {
  final String warehouseId, locationName;
  final int maxCapacity, usedShelves, availableShelves;
  const WarehouseAvailability({required this.warehouseId, required this.locationName,
      required this.maxCapacity, required this.usedShelves, required this.availableShelves});
  double get utilizationPercent => maxCapacity > 0 ? (usedShelves / maxCapacity) : 0.0;
  bool get hasAvailability => availableShelves > 0;
}
