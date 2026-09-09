import '../../data/models/inventory_response_model.dart';
import '../repositories/inventory_repository.dart';

/// Usecase for syncing pending offline queue items to the cloud broker.
class SyncOfflineQueueUsecase {
  final InventoryRepository _repository;

  SyncOfflineQueueUsecase(this._repository);

  Future<InventoryResponseModel<int>> invoke() {
    return _repository.syncOfflineQueue();
  }
}
