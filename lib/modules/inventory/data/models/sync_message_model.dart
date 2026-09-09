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

  /// Defensive JSON parsing ensuring malformed packets don't crash the app
  factory SyncMessageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SyncMessageModel(
        messageId: '',
        originDeviceId: '',
        action: 'noop',
        item: InventoryItemModel.fromJson(null),
        timestamp: DateTime.now().toUtc(),
        version: 1,
      );
    }

    DateTime parsedDate;
    try {
      final dynamic rawDate = json['timestamp'];
      if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate)?.toUtc() ?? DateTime.now().toUtc();
      } else {
        parsedDate = DateTime.now().toUtc();
      }
    } catch (_) {
      parsedDate = DateTime.now().toUtc();
    }

    return SyncMessageModel(
      messageId: json['messageId'] as String? ?? '',
      originDeviceId: json['originDeviceId'] as String? ?? '',
      action: json['action'] as String? ?? 'update_quantity',
      item: InventoryItemModel.fromJson(json['item'] as Map<String, dynamic>?),
      timestamp: parsedDate,
      version: (json['version'] as num?)?.toInt() ?? 1,
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
