import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

/// Professional loading state widget
/// Provides consistent loading UI across the app
class LoadingState extends StatelessWidget {
  final String? message;
  final bool showProgressIndicator;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingState({
    super.key,
    this.message,
    this.showProgressIndicator = true,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.scaffoldBackgroundColor;

    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showProgressIndicator)
              CircularProgressIndicator(
                valueColor: indicatorColor != null
                    ? AlwaysStoppedAnimation<Color>(indicatorColor!)
                    : null,
              ),
            if (message != null || showProgressIndicator) ...[
              const SizedBox(height: 24),
              Text(
                message ?? loc.getString('loading'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? barrierColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: barrierColor ?? Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

