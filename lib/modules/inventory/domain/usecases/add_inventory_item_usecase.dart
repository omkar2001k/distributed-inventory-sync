import '../../data/models/inventory_response_model.dart';
import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

/// Usecase for creating a new product item in the warehouse.
class AddInventoryItemUsecase {
  final InventoryRepository _repository;

  AddInventoryItemUsecase(this._repository);

  Future<InventoryResponseModel<InventoryItemEntity>> invoke(InventoryItemEntity item) {
    return _repository.addItem(item);
  }
}
