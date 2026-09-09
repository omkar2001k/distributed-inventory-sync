import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncstock/core/constants/app_constants.dart';
import 'package:syncstock/modules/inventory/domain/entities/sync_status_entity.dart';
import 'package:syncstock/modules/inventory/presentation/widgets/quantity_counter_button.dart';
import 'package:syncstock/modules/inventory/presentation/widgets/sync_status_badge.dart';

void main() {
  test('App constants are configured correctly', () {
    expect(AppConstants.appName, 'SyncStock');
    expect(AppConstants.mqttPort, 1883);
    expect(AppConstants.udpPort, 8888);
    expect(AppConstants.fallbackMqttBrokers.length, greaterThanOrEqualTo(2));
  });

  testWidgets('SyncStatusBadge renders in ultra-compact mode on mobile without overflowing', (WidgetTester tester) async {
    final status = SyncStatusEntity(
      mode: SyncMode.offline,
      statusMessage: 'Offline',
      pendingQueueCount: 6,
      activeTransport: 'Hive Cache',
      currentDeviceId: 'worker-1',
      lastSyncTime: DateTime(2026, 9, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 90, // Very tight mobile space
              child: SyncStatusBadge(
                syncStatus: status,
                isCompact: true,
              ),
            ),
          ),
        ),
      ),
    );

    // In compact mode, it should show '6', not '6 queued'
    expect(find.text('6'), findsOneWidget);
    expect(find.text('6 queued'), findsNothing);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('SyncStatusBadge renders full verbose text on desktop/tablet', (WidgetTester tester) async {
    final status = SyncStatusEntity(
      mode: SyncMode.offline,
      statusMessage: 'Offline',
      pendingQueueCount: 6,
      activeTransport: 'Hive Cache',
      currentDeviceId: 'worker-1',
      lastSyncTime: DateTime(2026, 9, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SyncStatusBadge(
              syncStatus: status,
              isCompact: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('6 queued'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('QuantityCounterButton renders and triggers callback', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuantityCounterButton(
            icon: Icons.add,
            tooltip: 'Increase',
            isEnabled: true,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(tapped, true);
  });

  testWidgets('QuantityCounterButton when disabled does not trigger callback', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuantityCounterButton(
            icon: Icons.remove,
            tooltip: 'Decrease',
            isEnabled: false,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(tapped, false);
  });
}
