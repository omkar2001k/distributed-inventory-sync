import 'dart:async';
import '../../../../core/network/http_service.dart';
import '../../../../core/network/mqtt_service.dart';
import '../../../../core/network/udp_service.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_response_model.dart';
import '../models/sync_message_model.dart';

/// Remote data source integrating MQTT Cloud Sync, Local UDP Broadcast, and HTTP catalog.
class InventoryRemoteDataSource {
  final MqttService mqttService;
  final UdpService udpService;
  final HttpService httpService;

  final _remoteMessageController = StreamController<SyncMessageModel>.broadcast();
  StreamSubscription<SyncMessageModel>? _mqttSubscription;
  StreamSubscription<SyncMessageModel>? _udpSubscription;

  InventoryRemoteDataSource({
    required this.mqttService,
    required this.udpService,
    required this.httpService,
  }) {
    _listenToSources();
  }

  void _listenToSources() {
    _mqttSubscription = mqttService.messageStream.listen((message) {
      _remoteMessageController.add(message);
    });

    _udpSubscription = udpService.messageStream.listen((message) {
      _remoteMessageController.add(message);
    });
  }

  Stream<SyncMessageModel> get remoteMessageStream => _remoteMessageController.stream;
  Stream<bool> get mqttConnectionStateStream => mqttService.connectionStateStream;

  bool get isMqttConnected => mqttService.isConnected;

  Future<bool> connectMqtt() => mqttService.connect();
  void disconnectMqtt() => mqttService.disconnect();

  Future<bool> startUdpListening() => udpService.startListening();
  void stopUdpListening() => udpService.stop();

  /// Publishes a change to the MQTT cloud broker.
  Future<bool> publishMqtt(SyncMessageModel message) {
    return mqttService.publish(message);
  }

  /// Broadcasts a change to the local Wi-Fi network over UDP.
  Future<bool> broadcastUdp(SyncMessageModel message) {
    return udpService.broadcast(message);
  }

  /// Fetches cloud inventory seed catalog via HTTP.
  Future<InventoryResponseModel<List<InventoryItemModel>>> fetchCloudCatalog() {
    return httpService.fetchRemoteCatalog();
  }

  void dispose() {
    _mqttSubscription?.cancel();
    _udpSubscription?.cancel();
    _remoteMessageController.close();
  }
}
