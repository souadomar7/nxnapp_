import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/inventory_repository.dart';

// States
abstract class InventoryState {
  const InventoryState();
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> movements;

  const InventoryLoaded({
    required this.items,
    required this.movements,
  });
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
}

// Cubit
class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;

  InventoryCubit({InventoryRepository? repository})
      : _repository = repository ?? InventoryRepository(),
        super(const InventoryInitial());

  Future<void> load() async {
    emit(const InventoryLoading());
    try {
      final items = await _repository.getMyInventory();
      final movements = await _repository.getMovements();
      emit(InventoryLoaded(items: items, movements: movements));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> recordMovement({
    required String productId,
    required String movementType,
    required int quantityDelta,
    String? warehouseId,
    String? shelfLabel,
    String? referenceType,
    String? notes,
  }) async {
    try {
      await _repository.recordMovement(
        productId: productId,
        movementType: movementType,
        quantityDelta: quantityDelta,
        warehouseId: warehouseId,
        shelfLabel: shelfLabel,
        referenceType: referenceType,
        notes: notes,
      );
      await load();
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
