import 'package:flutter/material.dart';

/// Reusable quantity adjustment button with disabled state protection.
class QuantityCounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isEnabled;
  final String tooltip;

  const QuantityCounterButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.isEnabled = true,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isEnabled ? activeColor.withAlpha(30) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled ? activeColor.withAlpha(90) : Colors.grey.withAlpha(40),
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isEnabled ? activeColor : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
