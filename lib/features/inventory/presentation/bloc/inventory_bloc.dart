import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/usecases/sync_inventory_usecase.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _repository;
  final SyncInventoryUseCase _syncInventoryUseCase;

  InventoryBloc({
    required InventoryRepository repository,
    required SyncInventoryUseCase syncInventoryUseCase,
  })  : _repository = repository,
        _syncInventoryUseCase = syncInventoryUseCase,
        super(InventoryInitial()) {
    on<LoadInventoryEvent>(_onLoadInventory);
    on<SyncInventoryEvent>(_onSyncInventory);
  }

  Future<void> _onLoadInventory(
    LoadInventoryEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final items = await _repository.getInventoryLocal();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventorySyncFailure(
        errorMessage: 'Failed to load local cached inventory: $e',
        cachedItems: const [],
      ));
    }
  }

  Future<void> _onSyncInventory(
    SyncInventoryEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final currentState = state;
    List<InventoryItem> cached = [];
    if (currentState is InventoryLoaded) {
      cached = currentState.items;
    } else if (currentState is InventorySyncFailure) {
      cached = currentState.cachedItems;
    }

    emit(InventoryLoading());
    try {
      // Execute synchronization domain Use Case
      await _syncInventoryUseCase(event.items, event.idempotencyKey);
      final updatedItems = await _repository.getInventoryLocal();
      emit(InventoryLoaded(updatedItems));
    } catch (e) {
      emit(InventorySyncFailure(
        errorMessage: e.toString(),
        cachedItems: cached,
      ));
    }
  }
}
