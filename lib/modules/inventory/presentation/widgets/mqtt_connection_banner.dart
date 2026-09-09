import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sync_status_entity.dart';

/// Interactive MQTT Connection Status Card displayed on the warehouse dashboard.
/// Clearly shows broker connection status (Connected, Connecting, Disconnected),
/// broker host (test.mosquitto.org:1883), and live sync topic.
class MqttConnectionBanner extends StatefulWidget {
  final SyncStatusEntity syncStatus;
  final VoidCallback? onReconnectPressed;

  const MqttConnectionBanner({
    super.key,
    required this.syncStatus,
    this.onReconnectPressed,
  });

  @override
  State<MqttConnectionBanner> createState() => _MqttConnectionBannerState();
}

class _MqttConnectionBannerState extends State<MqttConnectionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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

  bool get _isConnected =>
      widget.syncStatus.mode == SyncMode.online ||
      widget.syncStatus.isMqttConnected;

  Color get _accentColor {
    if (_isConnected) {
      return AppTheme.statusOnline;
    }
    if (widget.syncStatus.mode == SyncMode.localNetwork) {
      return AppTheme.statusLocal;
    }
    return AppTheme.statusOffline;
  }

  String get _statusText {
    if (_isConnected) {
      return 'Connected to test.mosquitto.org';
    }
    if (widget.syncStatus.mode == SyncMode.localNetwork) {
      return 'Local Network Only (P2P)';
    }
    return 'Disconnected from test.mosquitto.org';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = _accentColor;
    final isConnected = _isConnected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withAlpha(80),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Pulse Indicator
          ScaleTransition(
            scale: isConnected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(140),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Broker & Topic Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isConnected ? 'REAL-TIME SYNC' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Broker: ${AppConstants.mqttBroker}:${AppConstants.mqttPort} • Topic: ${AppConstants.mqttTopic}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Reconnect / Status Button
          if (!isConnected && widget.onReconnectPressed != null)
            TextButton.icon(
              onPressed: widget.onReconnectPressed,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Reconnect'),
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
