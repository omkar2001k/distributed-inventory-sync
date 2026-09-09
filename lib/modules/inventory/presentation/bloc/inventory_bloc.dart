import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/inventory_request_model.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/sync_status_entity.dart';
import '../../domain/usecases/add_inventory_item_usecase.dart';
import '../../domain/usecases/get_inventory_items_usecase.dart';
import '../../domain/usecases/reset_inventory_usecase.dart';
import '../../domain/usecases/set_simulation_mode_usecase.dart';
import '../../domain/usecases/sync_offline_queue_usecase.dart';
import '../../domain/usecases/update_quantity_usecase.dart';
import '../../domain/usecases/watch_inventory_stream_usecase.dart';
import '../../domain/usecases/watch_sync_status_usecase.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

/// Business Logic Component managing inventory state, real-time sync, and UI filtering.
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetInventoryItemsUsecase getInventoryItemsUsecase;
  final UpdateQuantityUsecase updateQuantityUsecase;
  final SyncOfflineQueueUsecase syncOfflineQueueUsecase;
  final WatchInventoryStreamUsecase watchInventoryStreamUsecase;
  final WatchSyncStatusUsecase watchSyncStatusUsecase;
  final AddInventoryItemUsecase addInventoryItemUsecase;
  final ResetInventoryUsecase resetInventoryUsecase;
  final SetSimulationModeUsecase setSimulationModeUsecase;

  StreamSubscription<List<InventoryItemEntity>>? _inventorySubscription;
  StreamSubscription<SyncStatusEntity>? _syncStatusSubscription;

  SyncStatusEntity _currentSyncStatus = SyncStatusEntity(
    mode: SyncMode.offline,
    statusMessage: 'Initializing...',
    pendingQueueCount: 0,
    activeTransport: 'Local Hive Cache',
    currentDeviceId: '',
    lastSyncTime: DateTime.now(),
  );

  InventoryBloc({
    required this.getInventoryItemsUsecase,
    required this.updateQuantityUsecase,
    required this.syncOfflineQueueUsecase,
    required this.watchInventoryStreamUsecase,
    required this.watchSyncStatusUsecase,
    required this.addInventoryItemUsecase,
    required this.resetInventoryUsecase,
    required this.setSimulationModeUsecase,
  }) : super(const InventoryInitialState()) {
    on<InventoryInitialEvent>(_onInventoryInitialEvent);
    on<UpdateItemQuantityEvent>(_onUpdateItemQuantityEvent);
    on<InventoryUpdatedFromStreamEvent>(_onInventoryUpdatedFromStreamEvent);
    on<SyncStatusUpdatedFromStreamEvent>(_onSyncStatusUpdatedFromStreamEvent);
    on<TriggerOfflineSyncEvent>(_onTriggerOfflineSyncEvent);
    on<AddNewInventoryItemEvent>(_onAddNewInventoryItemEvent);
    on<FilterInventoryEvent>(_onFilterInventoryEvent);
    on<SetSimulationModeEvent>(_onSetSimulationModeEvent);
    on<ResetInventoryToDefaultEvent>(_onResetInventoryToDefaultEvent);
  }

  Future<void> _onInventoryInitialEvent(
    InventoryInitialEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoadingState());

    // 1. Subscribe to continuous background updates
    _inventorySubscription?.cancel();
    _inventorySubscription = watchInventoryStreamUsecase.invoke().listen((items) {
      add(InventoryUpdatedFromStreamEvent(items));
    });

    _syncStatusSubscription?.cancel();
    _syncStatusSubscription = watchSyncStatusUsecase.invoke().listen((status) {
      add(SyncStatusUpdatedFromStreamEvent(status));
    });

    // 2. Fetch initial items
    final result = await getInventoryItemsUsecase.invoke();
    if (result.isSuccess && result.data != null) {
      final items = result.data!;
      emit(InventorySuccessState(
        allItems: items,
        filteredItems: items,
        syncStatus: _currentSyncStatus,
      ));
    } else {
      emit(InventoryFailureState(result.errorMessage ?? 'Failed to load inventory'));
    }
  }

  Future<void> _onUpdateItemQuantityEvent(
    UpdateItemQuantityEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final request = UpdateQuantityRequestModel(
      itemId: event.itemId,
      delta: event.delta,
      deviceId: _currentSyncStatus.currentDeviceId,
    );

    // Invoke usecase; the repository immediately updates local Hive & streams back new list
    await updateQuantityUsecase.invoke(request);
  }

  void _onInventoryUpdatedFromStreamEvent(
    InventoryUpdatedFromStreamEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventorySuccessState) {
      final current = state as InventorySuccessState;
      final filtered = _applyFilters(event.items, current.searchQuery, current.selectedCategory);
      emit(current.copyWith(
        allItems: event.items,
        filteredItems: filtered,
      ));
    } else {
      emit(InventorySuccessState(
        allItems: event.items,
        filteredItems: event.items,
        syncStatus: _currentSyncStatus,
      ));
    }
  }

  void _onSyncStatusUpdatedFromStreamEvent(
    SyncStatusUpdatedFromStreamEvent event,
    Emitter<InventoryState> emit,
  ) {
    _currentSyncStatus = event.syncStatus;
    if (state is InventorySuccessState) {
      final current = state as InventorySuccessState;
      emit(current.copyWith(syncStatus: event.syncStatus));
    }
  }

  Future<void> _onTriggerOfflineSyncEvent(
    TriggerOfflineSyncEvent event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventorySuccessState) {
      emit((state as InventorySuccessState).copyWith(isSyncingQueue: true));
    }

    await syncOfflineQueueUsecase.invoke();

    if (state is InventorySuccessState) {
      emit((state as InventorySuccessState).copyWith(isSyncingQueue: false));
    }
  }

  Future<void> _onAddNewInventoryItemEvent(
    AddNewInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    await addInventoryItemUsecase.invoke(event.item);
  }

  void _onFilterInventoryEvent(
    FilterInventoryEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventorySuccessState) {
      final current = state as InventorySuccessState;
      final query = event.searchQuery ?? current.searchQuery;
      final category = event.selectedCategory ?? current.selectedCategory;

      final filtered = _applyFilters(current.allItems, query, category);
      emit(current.copyWith(
        searchQuery: query,
        selectedCategory: category,
        filteredItems: filtered,
      ));
    }
  }

  Future<void> _onSetSimulationModeEvent(
    SetSimulationModeEvent event,
    Emitter<InventoryState> emit,
  ) async {
    await setSimulationModeUsecase.invoke(
      forcedMode: event.forcedMode,
      forcedDeviceId: event.forcedDeviceId,
    );
  }

  Future<void> _onResetInventoryToDefaultEvent(
    ResetInventoryToDefaultEvent event,
    Emitter<InventoryState> emit,
  ) async {
    await resetInventoryUsecase.invoke();
  }

  List<InventoryItemEntity> _applyFilters(
    List<InventoryItemEntity> source,
    String query,
    String category,
  ) {
    final cleanQuery = query.trim().toLowerCase();
    return source.where((item) {
      final matchesQuery = cleanQuery.isEmpty ||
          item.name.toLowerCase().contains(cleanQuery) ||
          item.sku.toLowerCase().contains(cleanQuery) ||
          item.category.toLowerCase().contains(cleanQuery);

      final matchesCategory = category == 'All' || item.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Future<void> close() {
    _inventorySubscription?.cancel();
    _syncStatusSubscription?.cancel();
    return super.close();
  }
}
