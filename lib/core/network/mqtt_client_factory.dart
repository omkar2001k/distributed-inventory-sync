import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_client_factory_stub.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_browser.dart'
    if (dart.library.io) 'mqtt_client_factory_server.dart';

/// Cross-platform factory creating MqttServerClient on Native and MqttBrowserClient on Web.
MqttClient createMqttClient({
  required String broker,
  required String clientId,
  required int tcpPort,
}) =>
    createPlatformMqttClient(
      broker: broker,
      clientId: clientId,
      tcpPort: tcpPort,
    );
