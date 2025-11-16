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

  // 2) Multiple Play Store Feature Graphic variants
  await _generateFeatureGraphicV1(baseIcon, outAndroid);
  await _generateFeatureGraphicV2(baseIcon, outAndroid);
  await _generateFeatureGraphicV3(baseIcon, outAndroid);

  stdout.writeln('✓ Generated:');
  stdout.writeln('  - $outIos/app_store_icon_1024.png');
  stdout.writeln('  - $outAndroid/feature_graphic_1024x500_v1.png');
  stdout.writeln('  - $outAndroid/feature_graphic_1024x500_v2.png');
  stdout.writeln('  - $outAndroid/feature_graphic_1024x500_v3.png');
}


Future<void> _generateFeatureGraphicV1(img.Image baseIcon, String outAndroid) async {
  const w = 1024, h = 500;
  final canvas = img.Image(width: w, height: h);
  // Brand gradient
  final start = img.ColorRgb8(185, 28, 28), end = img.ColorRgb8(229, 62, 62);
  _fillVerticalGradient(canvas, start, end);
  _applyEdgeVignette(canvas);
  // Center icon
  final ih = (h * 0.6).toInt(), iw = ih;
  final icon = img.copyResize(baseIcon, width: iw, height: ih, interpolation: img.Interpolation.cubic);
  img.compositeImage(canvas, icon, dstX: ((w - iw) / 2).round(), dstY: ((h - ih) / 2).round());
  await File('$outAndroid/feature_graphic_1024x500_v1.png').writeAsBytes(img.encodePng(canvas));
}

Future<void> _generateFeatureGraphicV2(img.Image baseIcon, String outAndroid) async {
  const w = 1024, h = 500;
  final canvas = img.Image(width: w, height: h);
  // Dark gradient
  final start = img.ColorRgb8(13, 17, 23), end = img.ColorRgb8(48, 54, 61);
  _fillVerticalGradient(canvas, start, end);
  // Left icon
  final ih = (h * 0.65).toInt(), iw = ih;
  final icon = img.copyResize(baseIcon, width: iw, height: ih, interpolation: img.Interpolation.cubic);
  final offY = ((h - ih) / 2).round();
  img.compositeImage(canvas, icon, dstX: 80, dstY: offY);
  // Title/subtitle overlay skipped to avoid font dependency; keep clean visual
  await File('$outAndroid/feature_graphic_1024x500_v2.png').writeAsBytes(img.encodePng(canvas));
}

Future<void> _generateFeatureGraphicV3(img.Image baseIcon, String outAndroid) async {
  const w = 1024, h = 500;
  final canvas = img.Image(width: w, height: h);
  // Light background
  final bg = img.ColorRgb8(248, 250, 252);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      canvas.setPixel(x, y, bg);
    }
  }
  // Right icon
  final ih = (h * 0.6).toInt(), iw = ih;
  final icon = img.copyResize(baseIcon, width: iw, height: ih, interpolation: img.Interpolation.cubic);
  final offY = ((h - ih) / 2).round();
  img.compositeImage(canvas, icon, dstX: w - iw - 80, dstY: offY);
  // Left-side caption removed (no font dependency); minimal layout
  await File('$outAndroid/feature_graphic_1024x500_v3.png').writeAsBytes(img.encodePng(canvas));
}

void _fillVerticalGradient(img.Image image, img.ColorRgb8 start, img.ColorRgb8 end) {
  final w = image.width, h = image.height;
  for (int y = 0; y < h; y++) {
    final t = y / (h - 1);
    final r = (start.r + (end.r - start.r) * t).toInt();
    final g = (start.g + (end.g - start.g) * t).toInt();
    final b = (start.b + (end.b - start.b) * t).toInt();
    final row = img.ColorRgb8(r, g, b);
    for (int x = 0; x < w; x++) {
      image.setPixel(x, y, row);
    }
  }
}

void _applyEdgeVignette(img.Image image) {
  final w = image.width, h = image.height;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final px = image.getPixel(x, y);
      final edgeX = (x < w / 2) ? x : (w - 1 - x);
      final edgeY = (y < h / 2) ? y : (h - 1 - y);
      final edge = (edgeX < edgeY ? edgeX : edgeY) / (h / 2);
      final fade = (0.85 + edge * 0.15).clamp(0.0, 1.0);
      image.setPixelRgb(x, y, (px.r * fade).toInt(), (px.g * fade).toInt(), (px.b * fade).toInt());
    }
  }
}
