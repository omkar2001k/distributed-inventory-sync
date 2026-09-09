/// Request Model for adjusting inventory item quantities.
class UpdateQuantityRequestModel {
  final String itemId;
  final int delta;
  final String deviceId;

  const UpdateQuantityRequestModel({
    required this.itemId,
    required this.delta,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'delta': delta,
      'deviceId': deviceId,
    };
  }
}

/// Request Model for adding a new inventory item.
class AddItemRequestModel {
  final String name;
  final String sku;
  final String category;
  final int initialQuantity;
  final int minStock;
  final String deviceId;

  const AddItemRequestModel({
    required this.name,
    required this.sku,
    required this.category,
    required this.initialQuantity,
    this.minStock = 5,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'category': category,
      'initialQuantity': initialQuantity,
      'minStock': minStock,
      'deviceId': deviceId,
    };
  }
}
