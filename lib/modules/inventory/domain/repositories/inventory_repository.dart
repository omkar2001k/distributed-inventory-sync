import '../../data/models/inventory_response_model.dart';
import '../entities/inventory_item_entity.dart';
import '../entities/sync_status_entity.dart';

/// Abstract contract defining inventory operations and sync synchronization.
abstract class InventoryRepository {
  /// Fetches current inventory items.
  Future<InventoryResponseModel<List<InventoryItemEntity>>> getInventoryItems();

  /// Updates quantity for a specific item (increment or decrement).
  Future<InventoryResponseModel<InventoryItemEntity>> updateQuantity({
    required String itemId,
    required int delta,
  });

  /// Adds a new inventory item to the warehouse catalog.
  Future<InventoryResponseModel<InventoryItemEntity>> addItem(InventoryItemEntity item);

  /// Synchronizes pending offline queue mutations to the cloud broker.
  Future<InventoryResponseModel<int>> syncOfflineQueue();

  /// Stream emitting real-time inventory updates from local and remote mutations.
  Stream<List<InventoryItemEntity>> watchInventory();

  /// Stream emitting current sync mode, queue count, and transport updates.
  Stream<SyncStatusEntity> watchSyncStatus();

  /// Switches active simulation mode (Online, Local UDP, Offline) or worker device ID.
  Future<void> setSimulationMode({
    SyncMode? forcedMode,
    String? forcedDeviceId,
  });

  /// Resets inventory to default catalog.
  Future<void> resetInventory();

  /// Device identifier for the current running client.
  String get currentDeviceId;
}
