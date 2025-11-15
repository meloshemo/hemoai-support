import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Simple controller to toggle a themed overlay banner with a localized title
/// during automated screenshots. Wire this via Provider in main.dart and
/// update its state from integration tests.
class ScreenshotOverlayService extends ChangeNotifier {
  bool _enabled = false;
  String? _localizedTitleKey;

  // A repaint boundary to wrap the entire app for high-fidelity screenshots.
  final GlobalKey repaintBoundaryKey = GlobalKey(debugLabel: 'screenshot_root_boundary');

  bool get enabled => _enabled;
  String? get localizedTitleKey => _localizedTitleKey;

  void show(String localizationKey) {
    _localizedTitleKey = localizationKey;
    if (!_enabled) {
      _enabled = true;
    }
    notifyListeners();
  }

  void updateTitle(String localizationKey) {
    _localizedTitleKey = localizationKey;
    if (_enabled) notifyListeners();
  }

  void hide() {
    if (_enabled || _localizedTitleKey != null) {
      _enabled = false;
      _localizedTitleKey = null;
      notifyListeners();
    }
  }

  /// Capture the wrapped repaint boundary to a PNG file on disk (non-web).
  Future<void> captureToFile(String filePath, {double pixelRatio = 3.0}) async {
    if (kIsWeb) return; // host-side file system not available in web tests
    final ctx = repaintBoundaryKey.currentContext;
    if (ctx == null) return;
    final render = ctx.findRenderObject();
    if (render is! RenderRepaintBoundary) return;
    final image = await render.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final file = io.File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());
  }

  /// Capture into the app's internal documents directory and return the path.
  /// This is accessible via `adb exec-out run-as <package>` on Android.
  Future<String?> captureToExternal(String fileName, {double pixelRatio = 3.0}) async {
    if (kIsWeb) return null;
    try {
      final ctx = repaintBoundaryKey.currentContext;
      if (ctx == null) return null;
      final render = ctx.findRenderObject();
      if (render is! RenderRepaintBoundary) return null;
      final image = await render.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // Use application documents directory for easier adb access via run-as
      final dir = await getApplicationDocumentsDirectory();
      final folder = io.Directory('${dir.path}/hemoai_screenshots');
      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }
      final file = io.File('${folder.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
