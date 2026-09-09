import 'inventory_item_model.dart';

/// Network sync packet payload transmitted across MQTT and UDP datagrams.
class SyncMessageModel {
  final String messageId;
  final String originDeviceId;
  final String action;
  final InventoryItemModel item;
  final DateTime timestamp;
  final int version;

  const SyncMessageModel({
    required this.messageId,
    required this.originDeviceId,
    required this.action,
    required this.item,
    required this.timestamp,
    required this.version,
  });

  /// Defensive JSON parsing supporting both dynamic Maps from Hive (Web & Native)
  /// and standard JSON deserialization without type cast exceptions.
  factory SyncMessageModel.fromJson(dynamic json) {
    if (json == null || json is! Map) {
      return SyncMessageModel(
        messageId: '',
        originDeviceId: '',
        action: 'noop',
        item: InventoryItemModel.fromJson(null),
        timestamp: DateTime.now().toUtc(),
        version: 1,
      );
    }

    final map = Map<String, dynamic>.from(json);

    DateTime parsedDate;
    try {
      final dynamic rawDate = map['timestamp'];
      if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate)?.toUtc() ?? DateTime.now().toUtc();
      } else {
        parsedDate = DateTime.now().toUtc();
      }
    } catch (_) {
      parsedDate = DateTime.now().toUtc();
    }

    final rawItem = map['item'];
    final itemModel = InventoryItemModel.fromJson(
      rawItem is Map ? Map<String, dynamic>.from(rawItem) : null,
    );

    return SyncMessageModel(
      messageId: map['messageId'] as String? ?? '',
      originDeviceId: map['originDeviceId'] as String? ?? '',
      action: map['action'] as String? ?? 'update_quantity',
      item: itemModel,
      timestamp: parsedDate,
      version: (map['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'originDeviceId': originDeviceId,
      'action': action,
      'item': item.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'version': version,
    };
  }
}
