import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../network/connectivity_service.dart';
import '../network/http_service.dart';
import '../network/mqtt_service.dart';
import '../network/udp_service.dart';
import '../../modules/inventory/data/datasources/inventory_local_datasource.dart';
import '../../modules/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../modules/inventory/data/repositories/inventory_repository_impl.dart';
import '../../modules/inventory/domain/repositories/inventory_repository.dart';
import '../../modules/inventory/domain/usecases/add_inventory_item_usecase.dart';
import '../../modules/inventory/domain/usecases/get_inventory_items_usecase.dart';
import '../../modules/inventory/domain/usecases/reset_inventory_usecase.dart';
import '../../modules/inventory/domain/usecases/set_simulation_mode_usecase.dart';
import '../../modules/inventory/domain/usecases/sync_offline_queue_usecase.dart';
import '../../modules/inventory/domain/usecases/update_quantity_usecase.dart';
import '../../modules/inventory/domain/usecases/watch_inventory_stream_usecase.dart';
import '../../modules/inventory/domain/usecases/watch_sync_status_usecase.dart';
import '../../modules/inventory/presentation/bloc/inventory_bloc.dart';

/// Lightweight dependency injection container matching 3 YOE developer standard.
/// No complicated reflection, simple and fast type-based lookup.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _registry = {};

  void registerSingleton<T>(T instance) {
    _registry[T] = instance;
  }

  void registerFactory<T>(T Function() factory) {
    _registry[T] = factory;
  }

  T get<T>() {
    final entry = _registry[T];
    if (entry == null) {
      throw StateError('ServiceLocator: No registration found for type $T');
    }
    if (entry is Function) {
      return entry() as T;
    }
    return entry as T;
  }
}

final serviceLocator = ServiceLocator();

/// Initializes all boxes, services, repositories, and usecases.
Future<void> setupServiceLocator({String? initialDeviceId}) async {
  // 1. Initialize Hive Boxes
  final inventoryBox = await Hive.openBox(AppConstants.inventoryBoxName);
  final syncQueueBox = await Hive.openBox(AppConstants.syncQueueBoxName);

  // 2. Core Network Services
  final clientId = initialDeviceId ?? 'worker_device_${DateTime.now().millisecondsSinceEpoch % 10000}';
  final mqttService = MqttService(clientId: clientId);
  final udpService = UdpService();
  final httpService = HttpService();
  final connectivityService = ConnectivityService();

  serviceLocator.registerSingleton<MqttService>(mqttService);
  serviceLocator.registerSingleton<UdpService>(udpService);
  serviceLocator.registerSingleton<HttpService>(httpService);
  serviceLocator.registerSingleton<ConnectivityService>(connectivityService);

  // 3. Data Sources
  final localDataSource = InventoryLocalDataSource(
    inventoryBox: inventoryBox,
    syncQueueBox: syncQueueBox,
  );
  final remoteDataSource = InventoryRemoteDataSource(
    mqttService: mqttService,
    udpService: udpService,
    httpService: httpService,
  );

  serviceLocator.registerSingleton<InventoryLocalDataSource>(localDataSource);
  serviceLocator.registerSingleton<InventoryRemoteDataSource>(remoteDataSource);

  // 4. Repository Implementation
  final inventoryRepository = InventoryRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    connectivityService: connectivityService,
    initialDeviceId: clientId,
  );
  serviceLocator.registerSingleton<InventoryRepository>(inventoryRepository);

  // 5. Domain Usecases
  serviceLocator.registerSingleton<GetInventoryItemsUsecase>(GetInventoryItemsUsecase(inventoryRepository));
  serviceLocator.registerSingleton<UpdateQuantityUsecase>(UpdateQuantityUsecase(inventoryRepository));
  serviceLocator.registerSingleton<SyncOfflineQueueUsecase>(SyncOfflineQueueUsecase(inventoryRepository));
  serviceLocator.registerSingleton<WatchInventoryStreamUsecase>(WatchInventoryStreamUsecase(inventoryRepository));
  serviceLocator.registerSingleton<WatchSyncStatusUsecase>(WatchSyncStatusUsecase(inventoryRepository));
  serviceLocator.registerSingleton<AddInventoryItemUsecase>(AddInventoryItemUsecase(inventoryRepository));
  serviceLocator.registerSingleton<ResetInventoryUsecase>(ResetInventoryUsecase(inventoryRepository));
  serviceLocator.registerSingleton<SetSimulationModeUsecase>(SetSimulationModeUsecase(inventoryRepository));

  // 6. Presentation BLoC factory
  serviceLocator.registerFactory<InventoryBloc>(() => InventoryBloc(
        getInventoryItemsUsecase: serviceLocator.get<GetInventoryItemsUsecase>(),
        updateQuantityUsecase: serviceLocator.get<UpdateQuantityUsecase>(),
        syncOfflineQueueUsecase: serviceLocator.get<SyncOfflineQueueUsecase>(),
        watchInventoryStreamUsecase: serviceLocator.get<WatchInventoryStreamUsecase>(),
        watchSyncStatusUsecase: serviceLocator.get<WatchSyncStatusUsecase>(),
        addInventoryItemUsecase: serviceLocator.get<AddInventoryItemUsecase>(),
        resetInventoryUsecase: serviceLocator.get<ResetInventoryUsecase>(),
        setSimulationModeUsecase: serviceLocator.get<SetSimulationModeUsecase>(),
      ));

  debugPrint('[DI] Service locator registered successfully.');
}
