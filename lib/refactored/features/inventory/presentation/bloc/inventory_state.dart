import 'package:equatable/equatable.dart';
import '../../../../../models/marketplace_models.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<SmeInventory> inventory;

  const InventoryLoaded(this.inventory);

  @override
  List<Object?> get props => [inventory];
}

class InventorySyncFailure extends InventoryState {
  final String errorMessage;
  final List<SmeInventory> cachedInventory;

  const InventorySyncFailure({
    required this.errorMessage,
    required this.cachedInventory,
  });

  @override
  List<Object?> get props => [errorMessage, cachedInventory];
}
