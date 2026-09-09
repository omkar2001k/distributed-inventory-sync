import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/sync_status_entity.dart';

/// Base state class for Inventory BLoC.
abstract class InventoryState {
  const InventoryState();
}

/// Initial state prior to data load.
final class InventoryInitialState extends InventoryState {
  const InventoryInitialState();
}

/// Loading state emitted during initial fetch or significant operations.
final class InventoryLoadingState extends InventoryState {
  const InventoryLoadingState();
}

/// Success state containing full list, filtered list, metrics, and sync status.
final class InventorySuccessState extends InventoryState {
  final List<InventoryItemEntity> allItems;
  final List<InventoryItemEntity> filteredItems;
  final SyncStatusEntity syncStatus;
  final String searchQuery;
  final String selectedCategory;
  final bool isSyncingQueue;

  const InventorySuccessState({
    required this.allItems,
    required this.filteredItems,
    required this.syncStatus,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.isSyncingQueue = false,
  });

  int get totalSkus => allItems.length;
  int get totalUnits => allItems.fold<int>(0, (sum, item) => sum + item.quantity);
  int get lowStockCount => allItems.where((i) => i.isLowStock).length;
  int get outOfStockCount => allItems.where((i) => i.isOutOfStock).length;

  List<String> get availableCategories {
    final categories = allItems.map((e) => e.category).toSet().toList()..sort();
    return ['All', ...categories];
  }

  InventorySuccessState copyWith({
    List<InventoryItemEntity>? allItems,
    List<InventoryItemEntity>? filteredItems,
    SyncStatusEntity? syncStatus,
    String? searchQuery,
    String? selectedCategory,
    bool? isSyncingQueue,
  }) {
    return InventorySuccessState(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      syncStatus: syncStatus ?? this.syncStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isSyncingQueue: isSyncingQueue ?? this.isSyncingQueue,
    );
  }
}

/// Failure state emitted when an unrecoverable error occurs.
final class InventoryFailureState extends InventoryState {
  final String errorMessage;

  const InventoryFailureState(this.errorMessage);
}
