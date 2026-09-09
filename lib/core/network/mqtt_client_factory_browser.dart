import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// Web browser MQTT client using WebSockets compatible with test.mosquitto.org.
/// Per the broker config, port 8080 uses `protocol websockets` with no custom path.
/// Port 8081 (wss://) is served by HAProxy with Let's Encrypt — more reliable in browsers.
MqttClient createPlatformMqttClient({
  required String broker,
  required String clientId,
  required int tcpPort,
}) {
  final isSecure = Uri.base.scheme == 'https';
  final wsScheme = isSecure ? 'wss' : 'ws';
  final wsPort = isSecure ? 8081 : 8080;
  final wsUrl = '$wsScheme://$broker';

  debugPrint('[MQTT BROWSER FACTORY] 🌐 Creating MqttBrowserClient');
  debugPrint('[MQTT BROWSER FACTORY]   URL: $wsUrl');
  debugPrint('[MQTT BROWSER FACTORY]   Port: $wsPort');
  debugPrint('[MQTT BROWSER FACTORY]   Transport: $wsScheme:// (WebSocket)');
  debugPrint('[MQTT BROWSER FACTORY]   Page scheme: ${Uri.base.scheme}');
  debugPrint(
    '[MQTT BROWSER FACTORY]   Subprotocol: ["mqtt"] (protocolsSingleDefault for Mosquitto)',
  );

  final client = MqttBrowserClient(wsUrl, clientId);
  client.port = wsPort;
  client.setProtocolV311();
  // CRITICAL: Mosquitto server drops the connection if multiple subprotocols are sent.
  // We must set protocolsSingleDefault (['mqtt']) so the WebSocket handshake completes successfully.
  client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  return client;
}
