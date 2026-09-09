import '../../data/models/inventory_request_model.dart';
import '../../data/models/inventory_response_model.dart';
import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

/// Usecase for incrementing or decrementing inventory quantities.
class UpdateQuantityUsecase {
  final InventoryRepository _repository;

  UpdateQuantityUsecase(this._repository);

  Future<InventoryResponseModel<InventoryItemEntity>> invoke(UpdateQuantityRequestModel request) {
    return _repository.updateQuantity(
      itemId: request.itemId,
      delta: request.delta,
    );
  }
}
