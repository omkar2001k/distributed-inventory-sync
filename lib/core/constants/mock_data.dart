import '../../modules/inventory/data/models/inventory_item_model.dart';

/// Seed data for initial warehouse inventory stock.
class MockWarehouseData {
  MockWarehouseData._();

  static List<InventoryItemModel> get initialItems => [
        InventoryItemModel(
          id: 'item-001',
          name: 'Heavy Duty Pallet Jack (2500kg)',
          sku: 'WH-EQ-101',
          category: 'Equipment',
          quantity: 8,
          minStock: 3,
          lastModified: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
          version: 1,
        ),
        InventoryItemModel(
          id: 'item-002',
          name: 'Wireless Barcode Scanner 2D',
          sku: 'WH-SC-204',
          category: 'Electronics',
          quantity: 24,
          minStock: 10,
          lastModified: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
          version: 1,
        ),
        InventoryItemModel(
          id: 'item-003',
          name: 'Thermal Shipping Labels 4x6 (Roll)',
          sku: 'WH-PKG-301',
          category: 'Packaging',
          quantity: 140,
          minStock: 50,
          lastModified: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          version: 1,
        ),
        InventoryItemModel(
          id: 'item-004',
          name: 'High-Visibility Safety Vest (L)',
          sku: 'WH-SAF-405',
          category: 'Safety',
          quantity: 42,
          minStock: 15,
          lastModified: DateTime.now().toUtc().subtract(const Duration(minutes: 45)),
          version: 1,
        ),
        InventoryItemModel(
          id: 'item-005',
          name: 'Heavy-Duty Stretch Wrap Film 500m',
          sku: 'WH-PKG-309',
          category: 'Packaging',
          quantity: 18,
          minStock: 12,
          lastModified: DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
          version: 1,
        ),
        InventoryItemModel(
          id: 'item-006',
          name: 'Lithium-Ion Forklift Battery Pack',
          sku: 'WH-PWR-501',
          category: 'Power & Battery',
          quantity: 4,
          minStock: 2,
          lastModified: DateTime.now().toUtc().subtract(const Duration(minutes: 15)),
          version: 1,
        ),
        InventoryItemModel(
          id: 'item-007',
          name: 'Stackable Industrial Storage Totes 60L',
          sku: 'WH-BIN-602',
          category: 'Storage',
          quantity: 75,
          minStock: 25,
          lastModified: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
          version: 1,
        ),
      ];
}
