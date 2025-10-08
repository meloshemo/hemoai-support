import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

class LoadingButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isDisabled;
  final ButtonStyle? style;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Duration animationDuration;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isDisabled = false,
    this.style,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isEnabled = onPressed != null && !isLoading && !isDisabled;
    
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.smallRadius),
          color: _getBackgroundColor(colorScheme, isEnabled),
          boxShadow: elevation != null
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: elevation!,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.smallRadius),
            child: Container(
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: AnimatedSwitcher(
                duration: animationDuration,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getForegroundColor(colorScheme, isEnabled),
                          ),
                        ),
                      )
                    : DefaultTextStyle(
                        style: TextStyle(
                          color: _getForegroundColor(colorScheme, isEnabled),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        child: child,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme, bool isEnabled) {
    if (backgroundColor != null) return backgroundColor!;
    
    if (!isEnabled) {
      return colorScheme.surfaceVariant;
    }
    
    return colorScheme.primary;
  }

  Color _getForegroundColor(ColorScheme colorScheme, bool isEnabled) {
    if (foregroundColor != null) return foregroundColor!;
    
    if (!isEnabled) {
      return colorScheme.onSurfaceVariant;
    }
    
    return colorScheme.onPrimary;
  }
}

// Specialized button variants
class PrimaryButton extends LoadingButton {
  const PrimaryButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  });
}

class SecondaryButton extends LoadingButton {
  const SecondaryButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
    super.backgroundColor,
    super.foregroundColor,
  });

  @override
  Color _getBackgroundColor(ColorScheme colorScheme, bool isEnabled) {
    if (backgroundColor != null) return backgroundColor!;
    
    if (!isEnabled) {
      return colorScheme.surfaceVariant;
    }
    
    return colorScheme.secondary;
  }

  @override
  Color _getForegroundColor(ColorScheme colorScheme, bool isEnabled) {
    if (foregroundColor != null) return foregroundColor!;
    
    if (!isEnabled) {
      return colorScheme.onSurfaceVariant;
    }
    
    return colorScheme.onSecondary;
  }
}

class OutlinedLoadingButton extends LoadingButton {
  const OutlinedLoadingButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
    super.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isEnabled = onPressed != null && !isLoading && !isDisabled;
    
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(
            color: _getBorderColor(colorScheme, isEnabled),
            width: 1.5,
          ),
          color: _getBackgroundColor(colorScheme, isEnabled),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.smallRadius),
            child: Container(
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: AnimatedSwitcher(
                duration: animationDuration,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getForegroundColor(colorScheme, isEnabled),
                          ),
                        ),
                      )
                    : DefaultTextStyle(
                        style: TextStyle(
                          color: _getForegroundColor(colorScheme, isEnabled),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        child: child,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(ColorScheme colorScheme, bool isEnabled) {
    if (!isEnabled) {
      return colorScheme.outline.withOpacity(0.5);
    }
    
    return colorScheme.primary;
  }

  @override
  Color _getBackgroundColor(ColorScheme colorScheme, bool isEnabled) {
    if (!isEnabled) {
      return colorScheme.surfaceVariant.withOpacity(0.5);
    }
    
    return Colors.transparent;
  }

  @override
  Color _getForegroundColor(ColorScheme colorScheme, bool isEnabled) {
    if (!isEnabled) {
      return colorScheme.onSurfaceVariant;
    }
    
    return colorScheme.primary;
  }
}

class TextLoadingButton extends LoadingButton {
  const TextLoadingButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.isLoading = false,
    super.isDisabled = false,
    super.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isEnabled = onPressed != null && !isLoading && !isDisabled;
    
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.smallRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: AnimatedSwitcher(
              duration: animationDuration,
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getForegroundColor(colorScheme, isEnabled),
                        ),
                      ),
                    )
                  : DefaultTextStyle(
                      style: TextStyle(
                        color: _getForegroundColor(colorScheme, isEnabled),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Color _getBackgroundColor(ColorScheme colorScheme, bool isEnabled) {
    return Colors.transparent;
  }

  @override
  Color _getForegroundColor(ColorScheme colorScheme, bool isEnabled) {
    if (!isEnabled) {
      return colorScheme.onSurfaceVariant;
    }
    
    return colorScheme.primary;
  }
}
