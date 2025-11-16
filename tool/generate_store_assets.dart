import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates store assets from the master icon:
/// - App Store Icon: 1024x1024
/// - Play Store Feature Graphic: 1024x500 (with brand gradient and centered icon)
///
/// Input:
/// - assets/icon/icon.png (1024x1024 recommended)
///
/// Output:
/// - store_assets/ios/app_store_icon_1024.png
/// - store_assets/android/feature_graphic_1024x500.png
Future<void> main() async {
  final iconPath = 'assets/icon/icon.png';
  final outIos = 'store_assets/ios';
  final outAndroid = 'store_assets/android';

  // Ensure output directories
  Directory(outIos).createSync(recursive: true);
  Directory(outAndroid).createSync(recursive: true);

  // Load base icon
  if (!File(iconPath).existsSync()) {
    stderr.writeln('ERROR: $iconPath not found. Place your 1024x1024 icon there.');
    exitCode = 1;
    return;
  }
  final iconBytes = await File(iconPath).readAsBytes();
  final baseIcon = img.decodeImage(iconBytes);
  if (baseIcon == null) {
    stderr.writeln('ERROR: Failed to decode $iconPath');
    exitCode = 2;
    return;
  }

  // 1) App Store Icon 1024x1024 (re-encode; ensure correct size)
  final appStoreIcon = img.copyResize(baseIcon, width: 1024, height: 1024, interpolation: img.Interpolation.linear);
  await File('$outIos/app_store_icon_1024.png').writeAsBytes(img.encodePng(appStoreIcon));

  // 2) Play Store Feature Graphic 1024x500
  const featureW = 1024;
  const featureH = 500;
  final feature = img.Image(width: featureW, height: featureH);

  // Background gradient (brand colors: #B91C1C → #E53E3E)
  final start = img.ColorRgb8(185, 28, 28); // #B91C1C
  final end = img.ColorRgb8(229, 62, 62);   // #E53E3E
  for (int y = 0; y < featureH; y++) {
    final t = y / (featureH - 1);
    final r = (start.r + (end.r - start.r) * t).toInt();
    final g = (start.g + (end.g - start.g) * t).toInt();
    final b = (start.b + (end.b - start.b) * t).toInt();
    final rowColor = img.ColorRgb8(r, g, b);
    for (int x = 0; x < featureW; x++) {
      feature.setPixel(x, y, rowColor);
    }
  }

  // Simple edge fade (vignette-lite)
  for (int y = 0; y < featureH; y++) {
    for (int x = 0; x < featureW; x++) {
      final px = feature.getPixel(x, y);
      final edgeX = (x < featureW / 2) ? x : (featureW - 1 - x);
      final edgeY = (y < featureH / 2) ? y : (featureH - 1 - y);
      final edge = (edgeX < edgeY ? edgeX : edgeY) / (featureH / 2);
      final fade = (0.85 + edge * 0.15).clamp(0.0, 1.0);
      feature.setPixelRgb(x, y, (px.r * fade).toInt(), (px.g * fade).toInt(), (px.b * fade).toInt());
    }
  }

  // Place icon centered (scale to 60% of height)
  final targetIconH = (featureH * 0.6).toInt();
  final targetIconW = targetIconH; // square
  final iconResized = img.copyResize(baseIcon, width: targetIconW, height: targetIconH, interpolation: img.Interpolation.cubic);
  final offsetX = ((featureW - targetIconW) / 2).round();
  final offsetY = ((featureH - targetIconH) / 2).round();

  // Composite icon
  img.compositeImage(feature, iconResized, dstX: offsetX, dstY: offsetY);

  await File('$outAndroid/feature_graphic_1024x500.png').writeAsBytes(img.encodePng(feature));

  stdout.writeln('✓ Generated:');
  stdout.writeln('  - $outIos/app_store_icon_1024.png');
  stdout.writeln('  - $outAndroid/feature_graphic_1024x500.png');
}


