import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../../domain/entities/sync_status_entity.dart';
import '../widgets/empty_inventory_view.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/mqtt_connection_banner.dart';
import '../widgets/network_simulation_bar.dart';
import '../widgets/sync_status_badge.dart';

/// Dynamic, fully-responsive visual layout of the warehouse inventory dashboard.
/// Adapts seamlessly across Mobile (< 600px), Tablet (600 - 1024px), and Desktop (> 1024px).
class InventoryDashboardView extends StatefulWidget {
  const InventoryDashboardView({super.key});

  @override
  State<InventoryDashboardView> createState() => _InventoryDashboardViewState();
}

class _InventoryDashboardViewState extends State<InventoryDashboardView> {
  final _searchController = TextEditingController();
  bool _showSimulationPanel = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<InventoryBloc>().add(FilterInventoryEvent(searchQuery: query));
  }

  void _onCategorySelected(String category) {
    context.read<InventoryBloc>().add(
      FilterInventoryEvent(selectedCategory: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile
        ? 12.0
        : (screenWidth < 1100 ? 20.0 : 24.0);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isMobile ? 12 : 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isMobile ? 32 : 38,
              height: isMobile ? 32 : 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary.withAlpha(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icon/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.warehouse_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SyncStock',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (!isMobile)
                    const Text(
                      'Distributed Inventory',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) {
              if (state is InventorySuccessState) {
                return Padding(
                  padding: EdgeInsets.only(right: isMobile ? 4 : 12),
                  child: SyncStatusBadge(
                    syncStatus: state.syncStatus,
                    isCompact: isMobile,
                    onTap: () {
                      setState(
                        () => _showSimulationPanel = !_showSimulationPanel,
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            tooltip: 'Testing Lab',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _showSimulationPanel ? Icons.tune_rounded : Icons.tune_outlined,
              color: _showSimulationPanel
                  ? theme.colorScheme.primary
                  : Colors.grey,
            ),
            onPressed: () {
              setState(() => _showSimulationPanel = !_showSimulationPanel);
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'More Options',
            onSelected: (val) {
              if (val == 'reset') {
                context.read<InventoryBloc>().add(
                  const ResetInventoryToDefaultEvent(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Catalog reset to default mock items'),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reset to Default Catalog'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: BlocConsumer<InventoryBloc, InventoryState>(
            listener: (context, state) {
              if (state is InventoryFailureState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: AppTheme.statusOffline,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is InventoryLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is InventoryFailureState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.statusOffline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<InventoryBloc>().add(
                          const InventoryInitialEvent(),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is InventorySuccessState) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<InventoryBloc>().add(
                      const TriggerOfflineSyncEvent(),
                    );
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Live MQTT Broker Connection Status
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            10,
                            horizontalPadding,
                            0,
                          ),
                          child: MqttConnectionBanner(
                            syncStatus: state.syncStatus,
                            onReconnectPressed: () {
                              context.read<InventoryBloc>().add(
                                const TriggerOfflineSyncEvent(),
                              );
                            },
                          ),
                        ),
                      ),

                      // 1. Interactive Simulation Testing Panel
                      if (_showSimulationPanel)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              6,
                              horizontalPadding,
                              6,
                            ),
                            child: NetworkSimulationBar(
                              syncStatus: state.syncStatus,
                              onSimulationChanged:
                                  (forcedMode, forcedDeviceId) {
                                    context.read<InventoryBloc>().add(
                                      SetSimulationModeEvent(
                                        forcedMode: forcedMode,
                                        forcedDeviceId: forcedDeviceId,
                                      ),
                                    );
                                  },
                              onManualSyncTriggered: () {
                                context.read<InventoryBloc>().add(
                                  const TriggerOfflineSyncEvent(),
                                );
                              },
                            ),
                          ),
                        ),

                      // Mobile Dedicated Status Strip (Shown when offline or mutations queued)
                      if (isMobile && (state.syncStatus.pendingQueueCount > 0 || state.syncStatus.mode == SyncMode.offline))
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              6,
                              horizontalPadding,
                              4,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (state.syncStatus.mode == SyncMode.offline
                                    ? AppTheme.statusOffline
                                    : AppTheme.statusLocal).withAlpha(22),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (state.syncStatus.mode == SyncMode.offline
                                      ? AppTheme.statusOffline
                                      : AppTheme.statusLocal).withAlpha(70),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    state.syncStatus.mode == SyncMode.offline
                                        ? Icons.cloud_off_rounded
                                        : Icons.wifi_tethering_rounded,
                                    size: 16,
                                    color: state.syncStatus.mode == SyncMode.offline
                                        ? AppTheme.statusOffline
                                        : AppTheme.statusLocal,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.syncStatus.pendingQueueCount > 0
                                          ? '${state.syncStatus.pendingQueueCount} mutations saved in Hive offline queue'
                                          : 'Offline mode active • Local Hive storage enabled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: state.syncStatus.mode == SyncMode.offline
                                            ? AppTheme.statusOffline
                                            : AppTheme.statusLocal,
                                      ),
                                    ),
                                  ),
                                  if (state.syncStatus.pendingQueueCount > 0)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        context.read<InventoryBloc>().add(
                                          const TriggerOfflineSyncEvent(),
                                        );
                                      },
                                      child: const Text(
                                        'Sync Now',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 2. Metrics KPI Row (Adapts: 2 columns on Mobile, 4 columns on Tablet/Desktop)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            10,
                            horizontalPadding,
                            12,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 600;
                              final cardWidth = isWide
                                  ? (constraints.maxWidth - 36) / 4
                                  : (constraints.maxWidth - 12) / 2;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: MetricCard(
                                      title: 'Total SKUs',
                                      value: '${state.totalSkus}',
                                      icon: Icons.inventory_2_rounded,
                                      accentColor: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: MetricCard(
                                      title: 'Stock Units',
                                      value: '${state.totalUnits}',
                                      icon: Icons.all_inbox_rounded,
                                      accentColor: AppTheme.secondaryIndigo,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: MetricCard(
                                      title: 'Low Stock Alert',
                                      value: '${state.lowStockCount}',
                                      icon: Icons.warning_amber_rounded,
                                      accentColor: AppTheme.statusLocal,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: MetricCard(
                                      title: 'Offline Queue',
                                      value:
                                          '${state.syncStatus.pendingQueueCount}',
                                      icon: Icons.queue_rounded,
                                      accentColor:
                                          state.syncStatus.pendingQueueCount > 0
                                          ? AppTheme.statusOffline
                                          : AppTheme.statusOnline,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      // 3. Search Bar and Category Chips
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search inventory by name, SKU, or category...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: state.availableCategories.map((
                                    cat,
                                  ) {
                                    final isSelected =
                                        state.selectedCategory == cat;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(cat),
                                        selected: isSelected,
                                        onSelected: (_) =>
                                            _onCategorySelected(cat),
                                        selectedColor: theme.colorScheme.primary
                                            .withAlpha(35),
                                        checkmarkColor:
                                            theme.colorScheme.primary,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),

                      // 4. Responsive Inventory Content (SliverList on Mobile, Dynamic Multi-Column SliverGrid on Tablet/Desktop)
                      if (state.filteredItems.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyInventoryView(
                            query: state.searchQuery,
                            onReset: () {
                              _searchController.clear();
                              context.read<InventoryBloc>().add(
                                const ResetInventoryToDefaultEvent(),
                              );
                            },
                          ),
                        )
                      else if (isMobile)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = state.filteredItems[index];
                              return InventoryItemCard(
                                key: ValueKey(item.id),
                                item: item,
                                onIncrement: () {
                                  context.read<InventoryBloc>().add(
                                    UpdateItemQuantityEvent(
                                      itemId: item.id,
                                      delta: 1,
                                    ),
                                  );
                                },
                                onDecrement: () {
                                  context.read<InventoryBloc>().add(
                                    UpdateItemQuantityEvent(
                                      itemId: item.id,
                                      delta: -1,
                                    ),
                                  );
                                },
                              );
                            }, childCount: state.filteredItems.length),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 440,
                                  mainAxisExtent: 220,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = state.filteredItems[index];
                              return InventoryItemCard(
                                key: ValueKey(item.id),
                                item: item,
                                margin: EdgeInsets.zero,
                                onIncrement: () {
                                  context.read<InventoryBloc>().add(
                                    UpdateItemQuantityEvent(
                                      itemId: item.id,
                                      delta: 1,
                                    ),
                                  );
                                },
                                onDecrement: () {
                                  context.read<InventoryBloc>().add(
                                    UpdateItemQuantityEvent(
                                      itemId: item.id,
                                      delta: -1,
                                    ),
                                  );
                                },
                              );
                            }, childCount: state.filteredItems.length),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
