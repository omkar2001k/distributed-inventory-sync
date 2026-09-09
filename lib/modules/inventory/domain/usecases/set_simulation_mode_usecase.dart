import '../entities/sync_status_entity.dart';
import '../repositories/inventory_repository.dart';

/// Usecase for manually toggling simulation mode (Online, UDP Local, Offline) or Worker Device ID.
class SetSimulationModeUsecase {
  final InventoryRepository _repository;

  SetSimulationModeUsecase(this._repository);

  Future<void> invoke({
    SyncMode? forcedMode,
    String? forcedDeviceId,
  }) {
    return _repository.setSimulationMode(
      forcedMode: forcedMode,
      forcedDeviceId: forcedDeviceId,
    );
  }
}
