import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../services/localization_service.dart';

/// Professional accessibility widgets
/// Provides consistent accessibility support across the app

/// Accessible button with proper semantics
class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final ButtonStyle? style;
  final bool isEnabled;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.style,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? tooltip,
      hint: isEnabled ? null : LocalizationService().getString('button_disabled'),
      button: true,
      enabled: isEnabled,
      child: Tooltip(
        message: tooltip ?? semanticLabel ?? '',
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: style,
          child: child,
        ),
      ),
    );
  }
}

/// Accessible icon button
class AccessibleIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;
  final double? iconSize;

  const AccessibleIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.semanticLabel,
    this.tooltip,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: onPressed == null ? LocalizationService().getString('button_disabled') : null,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: iconSize),
          tooltip: tooltip ?? semanticLabel,
        ),
      ),
    );
  }
}

/// Accessible text field
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? semanticLabel;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.semanticLabel,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? labelText,
      hint: hintText,
      textField: true,
      enabled: enabled,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        enabled: enabled,
      ),
    );
  }
}

/// Accessible card with semantic labels
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const AccessibleCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.onTap,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: margin,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        child: card,
      );
    }

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }

    return card;
  }
}

/// Accessible list tile
class AccessibleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      hint: subtitle,
      button: onTap != null,
      enabled: enabled,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        leading: leadingIcon != null ? Icon(leadingIcon) : null,
        trailing: trailing,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

/// Screen reader announcement helper
class ScreenReaderAnnouncement extends StatelessWidget {
  final String message;
  final bool excludeSemantics;

  const ScreenReaderAnnouncement({
    super.key,
    required this.message,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      excludeSemantics: excludeSemantics,
      child: const SizedBox.shrink(),
    );
  }
}

/// Helper to announce message to screen reader
void announceToScreenReader(BuildContext context, String message) {
  SemanticsService.announce(message, TextDirection.ltr);
}

