import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/sync_status_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_datasource.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_response_model.dart';
import '../models/sync_message_model.dart';

/// Concrete implementation of InventoryRepository.
/// Orchestrates local Hive storage, MQTT cloud sync, UDP fallback, and offline queue.
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource localDataSource;
  final InventoryRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  String _currentDeviceId;
  SyncMode? _forcedMode;
  bool _isDrainingQueue = false;

  final _inventoryStreamController = StreamController<List<InventoryItemEntity>>.broadcast();
  final _syncStatusStreamController = StreamController<SyncStatusEntity>.broadcast();

  StreamSubscription<SyncMessageModel>? _remoteMessageSubscription;
  StreamSubscription<bool>? _mqttStateSubscription;
  StreamSubscription<dynamic>? _connectivitySubscription;

  InventoryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
    String? initialDeviceId,
  }) : _currentDeviceId = initialDeviceId ?? 'worker-device-${const Uuid().v4().substring(0, 5)}' {
    _init();
  }

  @override
  String get currentDeviceId => _currentDeviceId;

  void _init() {
    // 1. Listen to incoming remote updates from MQTT & UDP
    _remoteMessageSubscription = remoteDataSource.remoteMessageStream.listen(_handleIncomingRemoteMessage);

    // 2. Listen to MQTT connection state changes
    _mqttStateSubscription = remoteDataSource.mqttConnectionStateStream.listen((isConnected) {
      debugPrint('[Repo] MQTT connection status changed: $isConnected');
      _evaluateSyncStateAndDrain();
    });

    // 3. Listen to network connectivity hardware changes
    _connectivitySubscription = connectivityService.onConnectivityChanged.listen((_) {
      debugPrint('[Repo] Network connectivity changed');
      _evaluateSyncStateAndDrain();
    });

    // 4. Initial network startup
    _startupNetworking();
  }

  Future<void> _startupNetworking() async {
    // Start UDP socket listener for local Wi-Fi peer discovery
    await remoteDataSource.startUdpListening();

    // Connect to MQTT Cloud broker
    await remoteDataSource.connectMqtt();

    // Evaluate initial sync state
    await _evaluateSyncStateAndDrain();
  }

  /// Evaluates current connection and drains queue if online.
  Future<void> _evaluateSyncStateAndDrain() async {
    final mode = await _determineCurrentMode();
    final pendingCount = localDataSource.pendingQueueCount;

    String transportDescription;
    String statusMessage;

    switch (mode) {
      case SyncMode.online:
        transportDescription = 'MQTT Cloud Broker (broker.emqx.io)';
        statusMessage = pendingCount > 0 ? 'Syncing $pendingCount queued items...' : 'Connected in real-time';
        break;
      case SyncMode.localNetwork:
        transportDescription = 'UDP Broadcast (255.255.255.255:8888)';
        statusMessage = 'Local Wi-Fi P2P Active';
        break;
      case SyncMode.offline:
        transportDescription = 'Local Hive Cache';
        statusMessage = pendingCount > 0 ? '$pendingCount changes queued locally' : 'Offline mode active';
        break;
    }

    _syncStatusStreamController.add(
      SyncStatusEntity(
        mode: mode,
        statusMessage: statusMessage,
        pendingQueueCount: pendingCount,
        activeTransport: transportDescription,
        currentDeviceId: _currentDeviceId,
        lastSyncTime: DateTime.now(),
      ),
    );

    // Automatically drain offline queue if we have transitioned to Online mode
    if (mode == SyncMode.online && pendingCount > 0 && !_isDrainingQueue) {
      await syncOfflineQueue();
    }
  }

  Future<SyncMode> _determineCurrentMode() async {
    if (_forcedMode != null) {
      return _forcedMode!;
    }

    if (remoteDataSource.isMqttConnected) {
      return SyncMode.online;
    }

    final hasWifi = await connectivityService.hasWifiConnection();
    if (hasWifi) {
      return SyncMode.localNetwork;
    }

    final hasNetwork = await connectivityService.hasNetworkConnection();
    if (!hasNetwork) {
      return SyncMode.offline;
    }

    // Default to local peer network or offline if MQTT is unreachable
    return SyncMode.localNetwork;
  }

  /// Edge Case 1: Self-Echo Loop Prevention
  /// Edge Case 2: Concurrent updates and out-of-order timestamps
  Future<void> _handleIncomingRemoteMessage(SyncMessageModel message) async {
    // 1. Ignore messages originated from this device to prevent infinite bounce loops
    if (message.originDeviceId == _currentDeviceId) {
      return;
    }

    debugPrint('[Repo] Received remote update for item ${message.item.id} from ${message.originDeviceId}');

    final currentItems = await localDataSource.getAllItems();
    final existingIndex = currentItems.indexWhere((i) => i.id == message.item.id);

    if (existingIndex != -1) {
      final existingItem = currentItems[existingIndex];

      // Version conflict resolution:
      // Accept update if:
      // 1. Incoming version is higher, OR
      // 2. Incoming version is equal AND timestamp is newer, OR
      // 3. Timestamps are identical and deterministic tie-breaker wins
      final isNewerVersion = message.item.version > existingItem.version;
      final isSameVersionNewerTime = message.item.version == existingItem.version &&
          message.item.lastModified.isAfter(existingItem.lastModified);
      final isTieBreakerWinner = message.item.version == existingItem.version &&
          message.item.lastModified.isAtSameMomentAs(existingItem.lastModified) &&
          message.originDeviceId.compareTo(_currentDeviceId) > 0;

      if (isNewerVersion || isSameVersionNewerTime || isTieBreakerWinner) {
        await localDataSource.saveItem(message.item);
        _notifyInventoryChange();
      } else {
        debugPrint('[Repo] Rejected older update for item ${message.item.id}');
      }
    } else {
      // New item added by peer
      await localDataSource.saveItem(message.item);
      _notifyInventoryChange();
    }
  }

  @override
  Future<InventoryResponseModel<List<InventoryItemEntity>>> getInventoryItems() async {
    try {
      final models = await localDataSource.getAllItems();
      final entities = models.map((m) => m.toEntity()).toList();
      _inventoryStreamController.add(entities);
      return InventoryResponseModel.success(data: entities);
    } catch (e) {
      return InventoryResponseModel.failure(errorMessage: 'Failed to load inventory: $e');
    }
  }

  @override
  Future<InventoryResponseModel<InventoryItemEntity>> updateQuantity({
    required String itemId,
    required int delta,
  }) async {
    try {
      final items = await localDataSource.getAllItems();
      final itemIndex = items.indexWhere((i) => i.id == itemId);

      if (itemIndex == -1) {
        return InventoryResponseModel.failure(errorMessage: 'Item not found');
      }

      final current = items[itemIndex];
      // Defensive guard against negative stock quantities
      final newQuantity = max(0, current.quantity + delta);

      final updatedItem = current.copyWith(
        quantity: newQuantity,
        lastModified: DateTime.now().toUtc(),
        version: current.version + 1,
      );

      // 1. Save immediately to local Hive cache (Optimistic UI update)
      await localDataSource.saveItem(updatedItem);
      _notifyInventoryChange();

      // 2. Prepare network payload
      final syncMessage = SyncMessageModel(
        messageId: const Uuid().v4(),
        originDeviceId: _currentDeviceId,
        action: 'update_quantity',
        item: updatedItem,
        timestamp: updatedItem.lastModified,
        version: updatedItem.version,
      );

      // 3. Determine transmission strategy based on current connectivity
      final activeMode = await _determineCurrentMode();

      switch (activeMode) {
        case SyncMode.online:
          final published = await remoteDataSource.publishMqtt(syncMessage);
          if (!published) {
            // If publish failed unexpectedly, queue for offline retry
            await localDataSource.addToSyncQueue(syncMessage);
          }
          break;

        case SyncMode.localNetwork:
          // Broadcast over UDP to nearby workers on the same Wi-Fi
          await remoteDataSource.broadcastUdp(syncMessage);
          // Also queue in Hive so it syncs to cloud broker when internet returns
          await localDataSource.addToSyncQueue(syncMessage);
          break;

        case SyncMode.offline:
          // Device is completely offline; queue mutation in Hive
          await localDataSource.addToSyncQueue(syncMessage);
          break;
      }

      await _evaluateSyncStateAndDrain();
      return InventoryResponseModel.success(data: updatedItem.toEntity());
    } catch (e) {
      return InventoryResponseModel.failure(errorMessage: 'Failed to update item: $e');
    }
  }

  @override
  Future<InventoryResponseModel<InventoryItemEntity>> addItem(InventoryItemEntity item) async {
    try {
      final model = InventoryItemModel.fromEntity(item);
      await localDataSource.saveItem(model);
      _notifyInventoryChange();

      final syncMessage = SyncMessageModel(
        messageId: const Uuid().v4(),
        originDeviceId: _currentDeviceId,
        action: 'add_item',
        item: model,
        timestamp: model.lastModified,
        version: model.version,
      );

      final activeMode = await _determineCurrentMode();
      if (activeMode == SyncMode.online) {
        await remoteDataSource.publishMqtt(syncMessage);
      } else if (activeMode == SyncMode.localNetwork) {
        await remoteDataSource.broadcastUdp(syncMessage);
        await localDataSource.addToSyncQueue(syncMessage);
      } else {
        await localDataSource.addToSyncQueue(syncMessage);
      }

      await _evaluateSyncStateAndDrain();
      return InventoryResponseModel.success(data: model.toEntity());
    } catch (e) {
      return InventoryResponseModel.failure(errorMessage: 'Failed to add item: $e');
    }
  }

  @override
  Future<InventoryResponseModel<int>> syncOfflineQueue() async {
    if (_isDrainingQueue) {
      return InventoryResponseModel.success(data: 0, message: 'Queue is already being processed');
    }

    _isDrainingQueue = true;
    int syncedCount = 0;

    try {
      final pendingQueue = await localDataSource.getPendingQueue();
      if (pendingQueue.isEmpty) {
        _isDrainingQueue = false;
        return InventoryResponseModel.success(data: 0, message: 'Queue is empty');
      }

      // Check if MQTT broker is available
      if (!remoteDataSource.isMqttConnected) {
        final connected = await remoteDataSource.connectMqtt();
        if (!connected) {
          _isDrainingQueue = false;
          return InventoryResponseModel.failure(errorMessage: 'MQTT Broker unreachable during queue drain');
        }
      }

      // Process in chronological order (FIFO)
      for (final message in pendingQueue) {
        final published = await remoteDataSource.publishMqtt(message);
        if (published) {
          await localDataSource.removeFromSyncQueue(message.messageId);
          syncedCount++;
        }
      }

      _isDrainingQueue = false;
      await _evaluateSyncStateAndDrain();
      return InventoryResponseModel.success(
        data: syncedCount,
        message: 'Successfully drained $syncedCount queued updates',
      );
    } catch (e) {
      _isDrainingQueue = false;
      return InventoryResponseModel.failure(errorMessage: 'Error during offline queue sync: $e');
    }
  }

  @override
  Stream<List<InventoryItemEntity>> watchInventory() => _inventoryStreamController.stream;

  @override
  Stream<SyncStatusEntity> watchSyncStatus() => _syncStatusStreamController.stream;

  @override
  Future<void> setSimulationMode({SyncMode? forcedMode, String? forcedDeviceId}) async {
    _forcedMode = forcedMode;
    if (forcedDeviceId != null && forcedDeviceId.isNotEmpty) {
      _currentDeviceId = forcedDeviceId;
    }

    if (forcedMode == SyncMode.offline) {
      remoteDataSource.disconnectMqtt();
    } else if (forcedMode == SyncMode.online) {
      await remoteDataSource.connectMqtt();
    }

    await _evaluateSyncStateAndDrain();
  }

  @override
  Future<void> resetInventory() async {
    await localDataSource.resetToDefault();
    _notifyInventoryChange();
    await _evaluateSyncStateAndDrain();
  }

  Future<void> _notifyInventoryChange() async {
    final items = await localDataSource.getAllItems();
    _inventoryStreamController.add(items.map((i) => i.toEntity()).toList());
  }

  void dispose() {
    _remoteMessageSubscription?.cancel();
    _mqttStateSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _inventoryStreamController.close();
    _syncStatusStreamController.close();
  }
}
