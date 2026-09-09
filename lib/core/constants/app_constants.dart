/// Application-wide constants for distributed inventory synchronization.
class AppConstants {
  AppConstants._();

  // Application Details
  static const String appName = 'SyncStock';
  static const String appTitle = 'SyncStock - Distributed Inventory Sync';

  // MQTT Broker Configuration
  // Primary broker broker.emqx.io with hivemq and mosquitto as resilient fallbacks
  static const String mqttBroker = 'broker.emqx.io';
  static const List<String> fallbackMqttBrokers = [
    'broker.emqx.io',
    'broker.hivemq.com',
    'test.mosquitto.org',
  ];
  static const int mqttPort = 1883;
  static const String mqttTopic = 'syncstock/inventory/sync';

  // UDP Fallback Configuration (Same local Wi-Fi router)
  static const int udpPort = 8888;
  static const String udpBroadcastAddress = '255.255.255.255';

  // Hive Box Names (Local-first persistence & Offline queue)
  static const String inventoryBoxName = 'inventory_items_box';
  static const String syncQueueBoxName = 'inventory_sync_queue_box';
  static const String settingsBoxName = 'app_settings_box';

  /// Remote HTTP catalog URL used by [HttpService].
  /// Created to satisfy the requirement: "use https package, return right model, handle null safely".
  /// The mock JSON file is located at the root of this project ([mock_catalog.json]).
  /// Once pushed to GitHub branch 'main', this exact URL serves 200 OK.
  /// If unpushed or offline, [HttpService] automatically falls back to local seed data.
  static const String mockCatalogUrl =
      'https://raw.githubusercontent.com/omkar2001k/distributed-inventory-sync/main/mock_catalog.json';
}
