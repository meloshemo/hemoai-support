import 'package:flutter/material.dart';

/// Image with semantics label enabled by default and graceful errorBuilder.
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String semanticsLabel;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.semanticsLabel,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image(
      image: image,
      fit: fit,
      width: width,
      height: height,
      semanticLabel: semanticsLabel,
      errorBuilder: (context, error, stack) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
      ),
    );

    final child = borderRadius != null
        ? ClipRRect(borderRadius: borderRadius ?? BorderRadius.circular(8), child: img)
        : img;

    return Semantics(
      label: semanticsLabel,
      image: true,
      child: child,
    );
  }
}
