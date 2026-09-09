import '../../domain/entities/inventory_item_entity.dart';

/// Data Model for Inventory Items supporting JSON serialization and Hive storage.
class InventoryItemModel {
  final String id;
  final String name;
  final String sku;
  final String category;
  final int quantity;
  final int minStock;
  final DateTime lastModified;
  final int version;

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.minStock,
    required this.lastModified,
    required this.version,
  });

  /// Defensive JSON deserialization with proper null safety and fallback values
  factory InventoryItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return InventoryItemModel(
        id: '',
        name: 'Unknown Item',
        sku: 'UNKNOWN',
        category: 'General',
        quantity: 0,
        minStock: 0,
        lastModified: DateTime.now().toUtc(),
        version: 1,
      );
    }

    DateTime parsedDate;
    try {
      final dynamic rawDate = json['lastModified'];
      if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate)?.toUtc() ?? DateTime.now().toUtc();
      } else if (rawDate is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate, isUtc: true);
      } else {
        parsedDate = DateTime.now().toUtc();
      }
    } catch (_) {
      parsedDate = DateTime.now().toUtc();
    }

    return InventoryItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Item',
      sku: json['sku'] as String? ?? 'SKU-NONE',
      category: json['category'] as String? ?? 'General',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      minStock: (json['minStock'] as num?)?.toInt() ?? 5,
      lastModified: parsedDate,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'quantity': quantity,
      'minStock': minStock,
      'lastModified': lastModified.toIso8601String(),
      'version': version,
    };
  }

  /// Maps domain entity to data model
  factory InventoryItemModel.fromEntity(InventoryItemEntity entity) {
    return InventoryItemModel(
      id: entity.id,
      name: entity.name,
      sku: entity.sku,
      category: entity.category,
      quantity: entity.quantity,
      minStock: entity.minStock,
      lastModified: entity.lastModified,
      version: entity.version,
    );
  }

  /// Maps data model to pure domain entity
  InventoryItemEntity toEntity() {
    return InventoryItemEntity(
      id: id,
      name: name,
      sku: sku,
      category: category,
      quantity: quantity,
      minStock: minStock,
      lastModified: lastModified,
      version: version,
    );
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    int? quantity,
    int? minStock,
    DateTime? lastModified,
    int? version,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      lastModified: lastModified ?? this.lastModified,
      version: version ?? this.version,
    );
  }
}
