import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/sync_status_entity.dart';

/// Base event class for inventory business logic component.
abstract class InventoryEvent {
  const InventoryEvent();
}

/// Dispatched on initial startup to load local inventory and start streams.
class InventoryInitialEvent extends InventoryEvent {
  const InventoryInitialEvent();
}

/// Dispatched when a worker taps "+" or "-" to adjust item quantity.
class UpdateItemQuantityEvent extends InventoryEvent {
  final String itemId;
  final int delta;

  const UpdateItemQuantityEvent({
    required this.itemId,
    required this.delta,
  });
}

/// Internal event triggered when the inventory stream receives local/remote updates.
class InventoryUpdatedFromStreamEvent extends InventoryEvent {
  final List<InventoryItemEntity> items;

  const InventoryUpdatedFromStreamEvent(this.items);
}

/// Internal event triggered when the sync status stream emits state changes.
class SyncStatusUpdatedFromStreamEvent extends InventoryEvent {
  final SyncStatusEntity syncStatus;

  const SyncStatusUpdatedFromStreamEvent(this.syncStatus);
}

/// Dispatched to manually trigger offline queue synchronization.
class TriggerOfflineSyncEvent extends InventoryEvent {
  const TriggerOfflineSyncEvent();
}

/// Dispatched when creating a new inventory item.
class AddNewInventoryItemEvent extends InventoryEvent {
  final InventoryItemEntity item;

  const AddNewInventoryItemEvent(this.item);
}

/// Dispatched when searching or filtering items by category.
class FilterInventoryEvent extends InventoryEvent {
  final String? searchQuery;
  final String? selectedCategory;

  const FilterInventoryEvent({
    this.searchQuery,
    this.selectedCategory,
  });
}

/// Dispatched to toggle testing simulation modes or switch worker identity.
class SetSimulationModeEvent extends InventoryEvent {
  final SyncMode? forcedMode;
  final String? forcedDeviceId;

  const SetSimulationModeEvent({
    this.forcedMode,
    this.forcedDeviceId,
  });
}

/// Dispatched to reset catalog to default seed data.
class ResetInventoryToDefaultEvent extends InventoryEvent {
  const ResetInventoryToDefaultEvent();
}
