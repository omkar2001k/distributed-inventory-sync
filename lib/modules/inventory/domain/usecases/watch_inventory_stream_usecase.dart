import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

/// Usecase for observing continuous real-time inventory updates.
class WatchInventoryStreamUsecase {
  final InventoryRepository _repository;

  WatchInventoryStreamUsecase(this._repository);

  Stream<List<InventoryItemEntity>> invoke() {
    return _repository.watchInventory();
  }
}
