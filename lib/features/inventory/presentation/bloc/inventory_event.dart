import 'package:equatable/equatable.dart';
import '../../domain/entities/inventory_item.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventoryEvent extends InventoryEvent {}

class SyncInventoryEvent extends InventoryEvent {
  final List<InventoryItem> items;
  final String idempotencyKey;

  const SyncInventoryEvent({
    required this.items,
    required this.idempotencyKey,
  });

  @override
  List<Object?> get props => [items, idempotencyKey];
}
