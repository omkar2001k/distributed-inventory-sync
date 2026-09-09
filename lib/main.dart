import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'modules/inventory/presentation/pages/inventory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive for local database persistence & offline queue
  await Hive.initFlutter();

  // 2. Set up Clean Architecture dependency injection
  await setupServiceLocator();

  // 3. Launch application
  runApp(const SyncStockApp());
}

/// Root Application Widget for SyncStock Distributed Inventory
class SyncStockApp extends StatelessWidget {
  const SyncStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const InventoryScreen(),
    );
  }
}
