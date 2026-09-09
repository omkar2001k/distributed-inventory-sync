import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/inventory_item_entity.dart';
import 'quantity_counter_button.dart';

/// Reusable card displaying an inventory item with interactive increment/decrement buttons.
class InventoryItemCard extends StatelessWidget {
  final InventoryItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final EdgeInsetsGeometry? margin;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (item.isOutOfStock) {
      statusColor = AppTheme.statusOffline;
      statusText = 'Out of Stock';
      statusIcon = Icons.cancel_outlined;
    } else if (item.isLowStock) {
      statusColor = AppTheme.statusLocal;
      statusText = 'Low Stock (${item.quantity}/${item.minStock})';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppTheme.statusOnline;
      statusText = 'In Stock';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    final formattedTime = DateFormat('HH:mm:ss').format(item.lastModified.toLocal());

    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Item Name & SKU
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${item.sku}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // Bottom Row: Stock Quantity & Stepper Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE UNITS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black45,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Text(
                        '${item.quantity}',
                        key: ValueKey<int>(item.quantity),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    QuantityCounterButton(
                      icon: Icons.remove,
                      tooltip: 'Decrease Quantity',
                      isEnabled: item.quantity > 0,
                      onPressed: onDecrement,
                      color: AppTheme.statusOffline,
                    ),
                    const SizedBox(width: 10),
                    QuantityCounterButton(
                      icon: Icons.add,
                      tooltip: 'Increase Quantity',
                      onPressed: onIncrement,
                      color: AppTheme.statusOnline,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 12, color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFF1F5F9)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'v${item.version}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  'Synced: $formattedTime',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
