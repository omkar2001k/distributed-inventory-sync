import 'package:flutter/material.dart';

/// Reusable empty state view when no inventory matches search or catalog is empty.
class EmptyInventoryView extends StatelessWidget {
  final String query;
  final VoidCallback onReset;

  const EmptyInventoryView({
    super.key,
    required this.query,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withAlpha(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'Warehouse is Empty' : 'No items matching "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'There are no active inventory items in the local database.'
                  : 'Try clearing your search query or selecting a different category.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Catalog to Default'),
            ),
          ],
        ),
      ),
    );
  }
}
