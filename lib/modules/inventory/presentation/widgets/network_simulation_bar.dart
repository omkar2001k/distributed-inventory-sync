import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sync_status_entity.dart';

/// Interactive Simulation Toolbar enabling easy testing of the 3 challenge scenarios:
/// 1. Cloud MQTT Sync (Online)
/// 2. Offline Queue (Hive)
/// 3. Local Peer-to-Peer Fallback (UDP)
class NetworkSimulationBar extends StatelessWidget {
  final SyncStatusEntity syncStatus;
  final Function(SyncMode? forcedMode, String? forcedDeviceId) onSimulationChanged;
  final VoidCallback onManualSyncTriggered;

  const NetworkSimulationBar({
    super.key,
    required this.syncStatus,
    required this.onSimulationChanged,
    required this.onManualSyncTriggered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'TESTING LAB',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              // Worker Device Identity Switcher
              PopupMenuButton<String>(
                tooltip: 'Switch Worker Identity',
                initialValue: syncStatus.currentDeviceId,
                onSelected: (newDeviceId) {
                  onSimulationChanged(null, newDeviceId);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_pin_rounded, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        syncStatus.currentDeviceId.isEmpty
                            ? 'Worker 1'
                            : syncStatus.currentDeviceId.contains('worker_2')
                                ? 'Worker 2 (Bob)'
                                : 'Worker 1 (Alice)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 14, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'worker_1_alice',
                    child: Text('Worker 1 (Alice)'),
                  ),
                  const PopupMenuItem(
                    value: 'worker_2_bob',
                    child: Text('Worker 2 (Bob)'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Simulation Mode Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeChip(
                  context: context,
                  label: 'Auto (Live Network)',
                  icon: Icons.autorenew_rounded,
                  color: AppTheme.primaryBlue,
                  isSelected: syncStatus.activeTransport.contains('Auto') ||
                      (!syncStatus.activeTransport.contains('Simulated')),
                  onTap: () => onSimulationChanged(null, null),
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context: context,
                  label: 'Force Cloud MQTT (test.mosquitto.org)',
                  icon: Icons.cloud_outlined,
                  color: AppTheme.statusOnline,
                  isSelected: syncStatus.mode == SyncMode.online,
                  onTap: () => onSimulationChanged(SyncMode.online, null),
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context: context,
                  label: 'Force Local UDP P2P',
                  icon: Icons.wifi_tethering_rounded,
                  color: AppTheme.statusLocal,
                  isSelected: syncStatus.mode == SyncMode.localNetwork,
                  onTap: () => onSimulationChanged(SyncMode.localNetwork, null),
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  context: context,
                  label: 'Force Offline Queue',
                  icon: Icons.cloud_off_rounded,
                  color: AppTheme.statusOffline,
                  isSelected: syncStatus.mode == SyncMode.offline,
                  onTap: () => onSimulationChanged(SyncMode.offline, null),
                ),
              ],
            ),
          ),

          if (syncStatus.pendingQueueCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.statusOffline.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.statusOffline.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_problem_rounded, size: 16, color: AppTheme.statusOffline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${syncStatus.pendingQueueCount} offline changes queued in Hive database',
                      style: const TextStyle(
                        color: AppTheme.statusOffline,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onManualSyncTriggered,
                    icon: const Icon(Icons.sync, size: 14),
                    label: const Text('Sync Now'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.statusOffline,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withAlpha(60),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
