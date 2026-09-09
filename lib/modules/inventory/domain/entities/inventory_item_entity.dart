/// Core domain entity representing an item in the warehouse inventory.
/// Kept pure and independent of external libraries or serialization.
class InventoryItemEntity {
  final String id;
  final String name;
  final String sku;
  final String category;
  final int quantity;
  final int minStock;
  final DateTime lastModified;
  final int version;

  const InventoryItemEntity({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.minStock,
    required this.lastModified,
    required this.version,
  });

  bool get isLowStock => quantity <= minStock && quantity > 0;
  bool get isOutOfStock => quantity == 0;

  InventoryItemEntity copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    int? quantity,
    int? minStock,
    DateTime? lastModified,
    int? version,
  }) {
    return InventoryItemEntity(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItemEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          quantity == other.quantity &&
          version == other.version;

  @override
  int get hashCode => id.hashCode ^ quantity.hashCode ^ version.hashCode;
}
