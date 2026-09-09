import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Native (Android, iOS, Windows, macOS, Linux) MQTT client using standard TCP socket.
MqttClient createPlatformMqttClient({
  required String broker,
  required String clientId,
  required int tcpPort,
}) {
  final client = MqttServerClient(broker, clientId);
  client.port = tcpPort;
  return client;
}
