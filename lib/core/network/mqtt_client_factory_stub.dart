import 'package:mqtt_client/mqtt_client.dart';

/// Stub implementation of platform MQTT client creator.
MqttClient createPlatformMqttClient({
  required String broker,
  required String clientId,
  required int tcpPort,
}) {
  throw UnsupportedError('Cannot create an MQTT client without dart:io or web libraries.');
}
