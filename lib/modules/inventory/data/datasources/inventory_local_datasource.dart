import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/inventory_item_model.dart';
import '../models/sync_message_model.dart';

/// Local data source powered by Hive.
/// Manages both local inventory persistence and the offline sync queue.
class InventoryLocalDataSource {
  final Box inventoryBox;
  final Box syncQueueBox;

  InventoryLocalDataSource({
    required this.inventoryBox,
    required this.syncQueueBox,
  });

  /// Retrieves all cached inventory items.
  /// If database is empty, seeds with initial mock warehouse catalog.
  Future<List<InventoryItemModel>> getAllItems() async {
    try {
      if (inventoryBox.isEmpty) {
        final initial = MockWarehouseData.initialItems;
        await saveAllItems(initial);
        return initial;
      }

      final items = <InventoryItemModel>[];
      for (final key in inventoryBox.keys) {
        final dynamic raw = inventoryBox.get(key);
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          items.add(InventoryItemModel.fromJson(map));
        }
      }

      // Sort by name for clean presentation
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    } catch (e) {
      debugPrint('[LocalDataSource] Error getting items: $e');
      return MockWarehouseData.initialItems;
    }
  }

  /// Persists a single item to local Hive storage.
  Future<void> saveItem(InventoryItemModel item) async {
    try {
      await inventoryBox.put(item.id, item.toJson());
    } catch (e) {
      debugPrint('[LocalDataSource] Error saving item ${item.id}: $e');
    }
  }

  /// Persists multiple items to Hive.
  Future<void> saveAllItems(List<InventoryItemModel> items) async {
    try {
      final map = <String, dynamic>{};
      for (final item in items) {
        map[item.id] = item.toJson();
      }
      await inventoryBox.putAll(map);
    } catch (e) {
      debugPrint('[LocalDataSource] Error saving all items: $e');
    }
  }

  /// Adds a mutation to the offline sync queue.
  Future<void> addToSyncQueue(SyncMessageModel message) async {
    try {
      await syncQueueBox.put(message.messageId, message.toJson());
      debugPrint('[LocalDataSource] Queued offline message: ${message.messageId}. Total queued: ${syncQueueBox.length}');
    } catch (e) {
      debugPrint('[LocalDataSource] Error adding to sync queue: $e');
    }
  }

  /// Retrieves all queued messages in FIFO order.
  Future<List<SyncMessageModel>> getPendingQueue() async {
    try {
      final messages = <SyncMessageModel>[];
      for (final key in syncQueueBox.keys) {
        final dynamic raw = syncQueueBox.get(key);
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          messages.add(SyncMessageModel.fromJson(map));
        }
      }
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      debugPrint('[LocalDataSource] Error reading sync queue: $e');
      return [];
    }
  }

  /// Removes an item from the offline sync queue once published.
  Future<void> removeFromSyncQueue(String messageId) async {
    try {
      await syncQueueBox.delete(messageId);
    } catch (e) {
      debugPrint('[LocalDataSource] Error removing from sync queue: $e');
    }
  }

  /// Number of pending offline changes.
  int get pendingQueueCount => syncQueueBox.length;

  /// Resets database back to default initial mock inventory.
  Future<List<InventoryItemModel>> resetToDefault() async {
    await inventoryBox.clear();
    await syncQueueBox.clear();
    final initial = MockWarehouseData.initialItems;
    await saveAllItems(initial);
    return initial;
  }
}
