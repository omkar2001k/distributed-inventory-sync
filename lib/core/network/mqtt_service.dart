import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../constants/app_constants.dart';
import '../../modules/inventory/data/models/sync_message_model.dart';

/// Service managing real-time cloud messaging over MQTT.
class MqttService {
  MqttServerClient? _client;
  final String clientId;

  final _messageController = StreamController<SyncMessageModel>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _brokerIndex = 0;

  MqttService({required this.clientId});

  Stream<SyncMessageModel> get messageStream => _messageController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  bool get isConnected => _isConnected;
  String get activeBroker =>
      AppConstants.fallbackMqttBrokers[_brokerIndex %
          AppConstants.fallbackMqttBrokers.length];

  /// Connects to the public MQTT broker with automatic broker failover.
  /// Uses [MqttServerClient] over standard TCP port (1883) for Mobile (Android/iOS)
  /// and Desktop platforms as required by the distributed warehouse challenge.
  Future<bool> connect() async {
    if (_isConnected) return true;
    if (_isConnecting) return false;

    _isConnecting = true;
    final broker = activeBroker;
    try {
      debugPrint(
        '[MQTT] Attempting connection to $broker (port ${AppConstants.mqttPort})...',
      );
      // MqttServerClient connects via standard TCP sockets for native mobile/desktop platforms
      final client = MqttServerClient(
        broker,
        '${clientId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      client.port = AppConstants.mqttPort; // Standard MQTT TCP port 1883
      client.keepAlivePeriod = 20;
      client.autoReconnect = true;
      client.logging(on: false);
      client.onConnected = _onConnected;
      client.onDisconnected = _onDisconnected;
      client.onSubscribed = (topic) =>
          debugPrint('[MQTT] Subscribed to $topic on $broker');

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(
            '${clientId}_${DateTime.now().millisecondsSinceEpoch}',
          )
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMessage;

      final status = await client.connect().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[MQTT] Connection timed out on $broker');
          client.disconnect();
          return null;
        },
      );

      if (status?.state == MqttConnectionState.connected) {
        _client = client;
        _isConnected = true;
        _isConnecting = false;
        _connectionStateController.add(true);

        client.subscribe(AppConstants.mqttTopic, MqttQos.atLeastOnce);
        _listenToIncomingMessages(client);
        return true;
      } else {
        _isConnecting = false;
        _isConnected = false;
        _connectionStateController.add(false);
        _brokerIndex++;
        _scheduleReconnect();
        return false;
      }
    } catch (e) {
      debugPrint('[MQTT] Connection failed on $broker: $e');
      _isConnecting = false;
      _isConnected = false;
      _connectionStateController.add(false);
      _brokerIndex++;
      _scheduleReconnect();
      return false;
    }
  }

  void _listenToIncomingMessages(MqttServerClient client) {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        try {
          final recMessage = message.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message,
          );

          final dynamic decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            final syncMessage = SyncMessageModel.fromJson(decoded);
            _messageController.add(syncMessage);
          }
        } catch (e) {
          debugPrint('[MQTT] Error parsing incoming packet: $e');
        }
      }
    });
  }

  /// Publishes a sync mutation payload to the MQTT topic.
  Future<bool> publish(SyncMessageModel message) async {
    if (!_isConnected || _client == null) {
      return false;
    }

    try {
      final jsonString = jsonEncode(message.toJson());
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonString);

      _client!.publishMessage(
        AppConstants.mqttTopic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
      return true;
    } catch (e) {
      debugPrint('[MQTT] Publish error: $e');
      return false;
    }
  }

  void _onConnected() {
    _isConnected = true;
    _isConnecting = false;
    _connectionStateController.add(true);
    debugPrint('[MQTT] Connected successfully to $activeBroker');
  }

  void _onDisconnected() {
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);
    debugPrint('[MQTT] Disconnected from broker');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _connectionStateController.add(false);
    try {
      _client?.disconnect();
    } catch (_) {}
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}
