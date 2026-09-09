import '../repositories/inventory_repository.dart';

/// Usecase for resetting inventory data back to default mock items.
class ResetInventoryUsecase {
  final InventoryRepository _repository;

  ResetInventoryUsecase(this._repository);

  Future<void> invoke() {
    return _repository.resetInventory();
  }
}
