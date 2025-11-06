import 'package:flutter/material.dart';

/// An IconButton with larger tap target, tooltip-as-semantics, and focus highlights.
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: iconSize, semanticLabel: tooltip),
          padding: padding,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ),
    );
  }
}
