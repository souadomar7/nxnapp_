import 'package:equatable/equatable.dart';
import '../../domain/entities/inventory_item.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> items;

  const InventoryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class InventorySyncFailure extends InventoryState {
  final String errorMessage;
  final List<InventoryItem> cachedItems;

  const InventorySyncFailure({
    required this.errorMessage,
    required this.cachedItems,
  });

  @override
  List<Object?> get props => [errorMessage, cachedItems];
}
