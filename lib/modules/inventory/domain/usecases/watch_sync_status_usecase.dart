import '../entities/sync_status_entity.dart';
import '../repositories/inventory_repository.dart';

/// Usecase for observing continuous sync status updates.
class WatchSyncStatusUsecase {
  final InventoryRepository _repository;

  WatchSyncStatusUsecase(this._repository);

  Stream<SyncStatusEntity> invoke() {
    return _repository.watchSyncStatus();
  }
}
