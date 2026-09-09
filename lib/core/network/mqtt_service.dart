import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../constants/app_constants.dart';
import '../../modules/inventory/data/models/sync_message_model.dart';
import 'mqtt_client_factory.dart';

/// Connection status enum for tracking MQTT connectivity to test.mosquitto.org.
enum MqttConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Service managing real-time cloud messaging exclusively over test.mosquitto.org.
/// Fully cross-platform: Uses TCP on Native (Android/iOS/Desktop) and WebSockets on Web.
class MqttService {
  MqttClient? _client;
  final String clientId;

  final _messageController = StreamController<SyncMessageModel>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _statusController = StreamController<MqttConnectionStatus>.broadcast();

  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  MqttConnectionStatus _status = MqttConnectionStatus.disconnected;

  MqttService({required this.clientId});

  Stream<SyncMessageModel> get messageStream => _messageController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<MqttConnectionStatus> get statusStream => _statusController.stream;
  bool get isConnected => _isConnected;
  MqttConnectionStatus get status => _status;
  String get activeBroker => AppConstants.mqttBroker;

  void _setStatus(MqttConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Connects to test.mosquitto.org using the platform-appropriate transport:
  /// TCP sockets (port 1883) on Native, or WebSockets (port 8080/8081) on Web.
  Future<bool> connect() async {
    if (_isConnected) return true;
    if (_isConnecting) return false;

    _isConnecting = true;
    _setStatus(MqttConnectionStatus.connecting);
    final broker = AppConstants.mqttBroker;
    final port = AppConstants.mqttPort;
    final generatedClientId = '${clientId}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final client = createMqttClient(
        broker: broker,
        clientId: generatedClientId,
        tcpPort: port,
      );

      final targetPort = client.port;
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[MQTT CONNECTION] 🔌 Initiating connection to $broker:$targetPort (${kIsWeb ? "WebSockets" : "TCP Sockets"})');
      debugPrint('[MQTT CONNECTION] 🆔 Client Identifier: $generatedClientId');
      debugPrint('[MQTT CONNECTION] 📡 Dedicated Broker: test.mosquitto.org (only public broker used)');

      client.keepAlivePeriod = 30;
      client.autoReconnect = false; // We manage reconnection manually via _scheduleReconnect
      client.logging(on: false);
      client.connectTimeoutPeriod = 20000; // 20s for WebSocket handshake
      client.onConnected = _onConnected;
      client.onDisconnected = _onDisconnected;
      client.onSubscribed = (topic) {
        debugPrint('[MQTT SUBSCRIPTION] 📥 Subscribed successfully to topic "$topic" on $broker');
        debugPrint('[MQTT LISTENER] 👂 Ready! Actively listening for incoming updates on topic "$topic"...');
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(generatedClientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMessage;

      final result = await client.connect().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('[MQTT CONNECTION] ⏱️ Timeout connecting to $broker:$targetPort');
          client.disconnect();
          return null;
        },
      );

      if (result?.state == MqttConnectionState.connected) {
        _client = client;
        _isConnected = true;
        _isConnecting = false;
        _setStatus(MqttConnectionStatus.connected);
        _connectionStateController.add(true);

        debugPrint('[MQTT CONNECTION] ✅ CONNECTED successfully to $broker:$port!');
        debugPrint('[MQTT TOPIC] 🎯 Subscribing to sync topic: ${AppConstants.mqttTopic}');

        client.subscribe(AppConstants.mqttTopic, MqttQos.atLeastOnce);
        _listenToIncomingMessages(client);
        return true;
      } else {
        debugPrint('[MQTT CONNECTION] ❌ Failed to establish connection state: ${result?.state}');
        _isConnecting = false;
        _isConnected = false;
        _setStatus(MqttConnectionStatus.error);
        _connectionStateController.add(false);
        _scheduleReconnect();
        return false;
      }
    } catch (e, stack) {
      debugPrint('[MQTT CONNECTION] ⚠️ Exception during connect to $broker: $e\n$stack');
      _isConnecting = false;
      _isConnected = false;
      _setStatus(MqttConnectionStatus.error);
      _connectionStateController.add(false);
      _scheduleReconnect();
      return false;
    }
  }

  /// Listens to updates from test.mosquitto.org and dispatches to subscribers.
  void _listenToIncomingMessages(MqttClient client) {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        try {
          final recMessage = message.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message,
          );

          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('[MQTT RECEIVER] 📬 New message received on topic: "${message.topic}"');
          debugPrint('[MQTT RECEIVER] 📦 Raw payload (${payload.length} chars): $payload');

          final dynamic decoded = jsonDecode(payload);
          if (decoded is Map) {
            final syncMessage = SyncMessageModel.fromJson(decoded);

            debugPrint('[MQTT RECEIVER] 🔍 Parsed SyncMessage:');
            debugPrint('   • Action: ${syncMessage.action}');
            debugPrint('   • Item: "${syncMessage.item.name}" (ID: ${syncMessage.item.id})');
            debugPrint('   • Quantity: ${syncMessage.item.quantity}');
            debugPrint('   • Version: ${syncMessage.version}');
            debugPrint('   • Origin Device ID: ${syncMessage.originDeviceId}');
            debugPrint('   • Timestamp: ${syncMessage.timestamp.toIso8601String()}');
            debugPrint('[MQTT DISPATCH] 🚀 Passing parsed payload to stream subscriber for instant UI refresh!');

            _messageController.add(syncMessage);
          } else {
            debugPrint('[MQTT RECEIVER] ⚠️ Decoded JSON is not a Map, ignoring');
          }
        } catch (e, stack) {
          debugPrint('[MQTT RECEIVER] ❌ Error parsing incoming packet: $e\n$stack');
        }
      }
    });
  }

  /// Publishes a sync mutation payload to test.mosquitto.org.
  Future<bool> publish(SyncMessageModel message) async {
    if (!_isConnected || _client == null) {
      debugPrint('[MQTT PUBLISH] ⚠️ Cannot publish: Not connected to ${AppConstants.mqttBroker}.');
      return false;
    }

    try {
      final jsonString = jsonEncode(message.toJson());
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonString);

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[MQTT PUBLISH] 📤 Publishing mutation to topic: "${AppConstants.mqttTopic}" on ${AppConstants.mqttBroker}');
      debugPrint('[MQTT PUBLISH] 📋 Details:');
      debugPrint('   • Action: ${message.action}');
      debugPrint('   • Item: "${message.item.name}" (ID: ${message.item.id})');
      debugPrint('   • New Quantity: ${message.item.quantity}');
      debugPrint('   • Version: ${message.version}');
      debugPrint('   • Origin Device ID: ${message.originDeviceId}');
      debugPrint('[MQTT PUBLISH] 📦 Payload JSON: $jsonString');

      _client!.publishMessage(
        AppConstants.mqttTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      debugPrint('[MQTT PUBLISH] ✅ Packet successfully published to ${AppConstants.mqttBroker}!');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return true;
    } catch (e) {
      debugPrint('[MQTT PUBLISH] ❌ Publish error on ${AppConstants.mqttBroker}: $e');
      return false;
    }
  }

  void _onConnected() {
    _isConnected = true;
    _isConnecting = false;
    _setStatus(MqttConnectionStatus.connected);
    _connectionStateController.add(true);
    debugPrint('[MQTT] ✅ Event: Connected successfully to ${AppConstants.mqttBroker}');
  }

  void _onDisconnected() {
    _isConnected = false;
    _isConnecting = false;
    _setStatus(MqttConnectionStatus.reconnecting);
    _connectionStateController.add(false);
    debugPrint('[MQTT] ❌ Event: Disconnected from ${AppConstants.mqttBroker}. Scheduling reconnect in 5s...');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('[MQTT] 🔄 Auto-reconnect triggered for ${AppConstants.mqttBroker}...');
        connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _isConnecting = false;
    _setStatus(MqttConnectionStatus.disconnected);
    _connectionStateController.add(false);
    try {
      _client?.disconnect();
    } catch (_) {}
    debugPrint('[MQTT] ⏹️ Client disconnected on demand');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
    _statusController.close();
  }
}
