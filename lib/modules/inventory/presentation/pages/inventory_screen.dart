import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../views/inventory_dashboard_view.dart';

/// Screen component providing BLoC to the visual tree and binding initial events.
/// Strictly follows Clean Architecture structure specified in documentation.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InventoryBloc>(
      create: (context) => serviceLocator.get<InventoryBloc>()
        ..add(const InventoryInitialEvent()),
      child: const InventoryDashboardView(),
    );
  }
}
