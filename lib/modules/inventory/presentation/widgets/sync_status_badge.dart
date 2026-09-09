import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sync_status_entity.dart';

/// Reusable badge widget indicating current synchronization state.
/// Displays 🟢 Online, 🟡 Local Network Only, or 🔴 Offline with active queue indicator.
class SyncStatusBadge extends StatefulWidget {
  final SyncStatusEntity syncStatus;
  final VoidCallback? onTap;
  final bool isCompact;

  const SyncStatusBadge({
    super.key,
    required this.syncStatus,
    this.onTap,
    this.isCompact = false,
  });

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.syncStatus.mode) {
      case SyncMode.online:
        return AppTheme.statusOnline;
      case SyncMode.localNetwork:
        return AppTheme.statusLocal;
      case SyncMode.offline:
        return AppTheme.statusOffline;
    }
  }

  String get _statusLabel {
    switch (widget.syncStatus.mode) {
      case SyncMode.online:
        return 'Online';
      case SyncMode.localNetwork:
        return widget.isCompact ? 'Local Network' : 'Local Network Only';
      case SyncMode.offline:
        return 'Offline';
    }
  }

  IconData get _statusIcon {
    switch (widget.syncStatus.mode) {
      case SyncMode.online:
        return Icons.cloud_done_rounded;
      case SyncMode.localNetwork:
        return Icons.wifi_tethering_rounded;
      case SyncMode.offline:
        return Icons.cloud_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final isCompact = widget.isCompact;

    return Tooltip(
      message: '${widget.syncStatus.statusMessage} • Tap for controls',
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withAlpha(80), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: isCompact ? 7 : 9,
                  height: isCompact ? 7 : 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withAlpha(120),
                        blurRadius: isCompact ? 4 : 6,
                        spreadRadius: isCompact ? 1 : 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 5 : 8),
              Icon(_statusIcon, size: isCompact ? 13 : 14, color: statusColor),
              if (!isCompact) ...[
                const SizedBox(width: 6),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
              if (widget.syncStatus.pendingQueueCount > 0) ...[
                SizedBox(width: isCompact ? 4 : 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 5 : 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.statusOffline,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isCompact
                        ? '${widget.syncStatus.pendingQueueCount}'
                        : '${widget.syncStatus.pendingQueueCount} queued',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 9 : 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
