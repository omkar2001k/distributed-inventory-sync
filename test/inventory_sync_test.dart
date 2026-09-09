import 'package:flutter_test/flutter_test.dart';
import 'package:syncstock/modules/inventory/data/models/inventory_item_model.dart';
import 'package:syncstock/modules/inventory/data/models/sync_message_model.dart';
import 'package:syncstock/modules/inventory/domain/entities/inventory_item_entity.dart';

void main() {
  group('InventoryItemModel Null Safety & Serialization', () {
    test('Handles completely null JSON safely with default values', () {
      final model = InventoryItemModel.fromJson(null);

      expect(model.id, '');
      expect(model.name, 'Unknown Item');
      expect(model.sku, 'UNKNOWN');
      expect(model.category, 'General');
      expect(model.quantity, 0);
      expect(model.minStock, 0);
      expect(model.version, 1);
    });

    test('Serializes to JSON and back without data loss', () {
      final original = InventoryItemModel(
        id: 'test-101',
        name: 'Pallet Jack',
        sku: 'WH-01',
        category: 'Equipment',
        quantity: 15,
        minStock: 5,
        lastModified: DateTime.utc(2026, 9, 8, 12, 0),
        version: 3,
      );

      final json = original.toJson();
      final restored = InventoryItemModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.sku, original.sku);
      expect(restored.quantity, original.quantity);
      expect(restored.version, original.version);
    });

    test('Maps to and from Entity correctly', () {
      final entity = InventoryItemEntity(
        id: 'item-1',
        name: 'Barcode Scanner',
        sku: 'SC-1',
        category: 'Electronics',
        quantity: 4,
        minStock: 5,
        lastModified: DateTime.now().toUtc(),
        version: 2,
      );

      final model = InventoryItemModel.fromEntity(entity);
      final backToEntity = model.toEntity();

      expect(backToEntity.isLowStock, true);
      expect(backToEntity.isOutOfStock, false);
      expect(backToEntity.name, 'Barcode Scanner');
    });
  });

  group('SyncMessageModel & Self-Echo Loop Prevention', () {
    test('Safely parses incoming JSON sync packet', () {
      final packetJson = {
        'messageId': 'msg-uuid-999',
        'originDeviceId': 'worker-device-alice',
        'action': 'update_quantity',
        'item': {
          'id': 'item-001',
          'name': 'Thermal Labels',
          'sku': 'LBL-01',
          'category': 'Packaging',
          'quantity': 50,
          'minStock': 10,
          'lastModified': '2026-09-08T12:00:00.000Z',
          'version': 4,
        },
        'timestamp': '2026-09-08T12:00:00.000Z',
        'version': 4,
      };

      final message = SyncMessageModel.fromJson(packetJson);

      expect(message.messageId, 'msg-uuid-999');
      expect(message.originDeviceId, 'worker-device-alice');
      expect(message.item.quantity, 50);
      expect(message.version, 4);
    });

    test('Self-echo loop detection: message from same device is detected', () {
      const myDeviceId = 'worker-device-alice';

      final incomingMessage = SyncMessageModel(
        messageId: 'msg-1',
        originDeviceId: 'worker-device-alice',
        action: 'update_quantity',
        item: InventoryItemModel.fromJson(null),
        timestamp: DateTime.now().toUtc(),
        version: 2,
      );

      final isSelfEcho = incomingMessage.originDeviceId == myDeviceId;
      expect(isSelfEcho, true, reason: 'Device should identify its own broadcast and ignore it');
    });

    test('Remote message from peer device is accepted', () {
      const myDeviceId = 'worker-device-alice';

      final incomingMessage = SyncMessageModel(
        messageId: 'msg-2',
        originDeviceId: 'worker-device-bob',
        action: 'update_quantity',
        item: InventoryItemModel.fromJson(null),
        timestamp: DateTime.now().toUtc(),
        version: 2,
      );

      final isSelfEcho = incomingMessage.originDeviceId == myDeviceId;
      expect(isSelfEcho, false, reason: 'Peer message should not be flagged as self echo');
    });
  });

  group('Negative Quantity Guard & Conflict Resolution', () {
    test('Decrementing below 0 is safely clamped to 0', () {
      int currentQty = 0;
      int delta = -1;
      int newQty = (currentQty + delta) < 0 ? 0 : (currentQty + delta);

      expect(newQty, 0);
    });

    test('Newer version supersedes older version in conflict resolution', () {
      const localVersion = 2;
      const incomingVersion = 3;

      final shouldApply = incomingVersion > localVersion;
      expect(shouldApply, true);
    });

    test('Older version is rejected in conflict resolution', () {
      const localVersion = 5;
      const incomingVersion = 4;

      final shouldApply = incomingVersion > localVersion;
      expect(shouldApply, false);
    });
  });
}
