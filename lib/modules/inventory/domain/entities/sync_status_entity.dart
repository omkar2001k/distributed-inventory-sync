import '../../../../core/constants/app_constants.dart';

/// The visual and operational sync states for the application.
enum SyncMode {
  /// 🟢 Online: Communicating in real-time over MQTT Cloud broker (test.mosquitto.org).
  online,

  /// 🟡 Local Network Only: Communicating peer-to-peer via UDP broadcast on local Wi-Fi.
  localNetwork,

  /// 🔴 Offline: Device has no internet or local peers; changes queued locally in Hive.
  offline,
}

/// Domain entity representing real-time synchronization state.
class SyncStatusEntity {
  final SyncMode mode;
  final String statusMessage;
  final int pendingQueueCount;
  final String activeTransport;
  final String currentDeviceId;
  final DateTime lastSyncTime;
  final String mqttBroker;
  final bool isMqttConnected;

  const SyncStatusEntity({
    required this.mode,
    required this.statusMessage,
    required this.pendingQueueCount,
    required this.activeTransport,
    required this.currentDeviceId,
    required this.lastSyncTime,
    this.mqttBroker = AppConstants.mqttBroker,
    this.isMqttConnected = false,
  });

  SyncStatusEntity copyWith({
    SyncMode? mode,
    String? statusMessage,
    int? pendingQueueCount,
    String? activeTransport,
    String? currentDeviceId,
    DateTime? lastSyncTime,
    String? mqttBroker,
    bool? isMqttConnected,
  }) {
    return SyncStatusEntity(
      mode: mode ?? this.mode,
      statusMessage: statusMessage ?? this.statusMessage,
      pendingQueueCount: pendingQueueCount ?? this.pendingQueueCount,
      activeTransport: activeTransport ?? this.activeTransport,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      mqttBroker: mqttBroker ?? this.mqttBroker,
      isMqttConnected: isMqttConnected ?? this.isMqttConnected,
    );
  }
}
