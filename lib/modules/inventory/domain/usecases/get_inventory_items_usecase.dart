import '../../data/models/inventory_response_model.dart';
import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

/// Usecase for retrieving all inventory items.
class GetInventoryItemsUsecase {
  final InventoryRepository _repository;

  GetInventoryItemsUsecase(this._repository);

  Future<InventoryResponseModel<List<InventoryItemEntity>>> invoke() {
    return _repository.getInventoryItems();
  }
}
