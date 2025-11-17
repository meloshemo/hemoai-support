// ignore_for_file: unnecessary_cast, unnecessary_brace_in_string_interps, no_leading_underscores_for_local_identifiers, unintended_html_in_doc_comment, unnecessary_null_comparison, unnecessary_string_interpolations

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:hemoai/main.dart' as app;
import 'package:hemoai/services/preferences_service.dart';
import 'package:hemoai/services/screenshot_overlay_service.dart';
import 'package:hemoai/services/theme_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

/// Drives core screens and captures store screenshots.
/// Run:
///   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_flow_test.dart -d <device>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;

  // Helpers come first to avoid forward-reference errors in Dart
  RenderRepaintBoundary? findRepaintBoundaryInTree(RenderObject? root) {
    if (root == null) return null;
    if (root is RenderRepaintBoundary) return root;
    RenderRepaintBoundary? result;
    root.visitChildren((RenderObject child) {
      result ??= findRepaintBoundaryInTree(child);
    });
    return result;
  }

  Future<void> _saveRenderBoundary(RenderRepaintBoundary boundary, String name) async {
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('Failed to convert image to byte data');
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      Directory outDir;
      if (Platform.isAndroid || Platform.isIOS) {
        final docs = await getApplicationDocumentsDirectory();
        outDir = Directory(p.join(docs.path, 'hemoai_screens'));
        if (!await outDir.exists()) { await outDir.create(recursive: true); }
      } else {
        outDir = Directory('screenshots');
        if (!await outDir.exists()) { await outDir.create(recursive: true); }
      }
      final file = File(p.join(outDir.path, '$name.png'));
      await file.writeAsBytes(bytes, flush: true);
      final fileSizeKB = (bytes.length / 1024).toStringAsFixed(2);
      debugPrint('  → Saved: ${file.path} (${fileSizeKB} KB)');
      if (Platform.isAndroid) {
        debugPrint('  ↳ Pull with: adb pull "${outDir.path}" .\\screenshots');

        // Also copy to external storage for easier adb pull (no run-as needed)
        try {
          final external = await getExternalStorageDirectory();
          if (external != null) {
            final extDir = Directory(p.join(external.path, 'hemoai_screens'));
            if (!await extDir.exists()) { await extDir.create(recursive: true); }
            final extFile = File(p.join(extDir.path, '$name.png'));
            await extFile.writeAsBytes(bytes, flush: true);
            debugPrint('  → Copied to external: ${extFile.path}');
            debugPrint('  ↳ Pull with: adb pull "${extDir.path}" .\\screenshots-android');
          }
        } catch (e) {
          debugPrint('External copy failed: $e');
        }
      } else if (Platform.isIOS) {
        debugPrint('  ↳ iOS sim path: ${outDir.path}');
      }
    } catch (e) {
      debugPrint('Save error: $e');
      rethrow;
    }
  }

  Future<void> _captureAndSaveScreenshot(String name, WidgetTester tester) async {
    try {
      // Ensure surface size before each capture in case a screen changed it
      await tester.binding.setSurfaceSize(Platform.isWindows
          ? const Size(1440, 2800)
          : const Size(1080, 2400));
      await tester.pump(const Duration(milliseconds: 300));
      RenderRepaintBoundary? boundary;
      try {
        final appFinder = find.byType(MaterialApp);
        if (appFinder.evaluate().isNotEmpty) {
          final appElement = tester.element(appFinder.first);
          final screenshotService = Provider.of<ScreenshotOverlayService>(appElement, listen: false);
          final key = screenshotService.repaintBoundaryKey;
          final keyFinder = find.byKey(key);
          if (keyFinder.evaluate().isNotEmpty) {
            boundary = tester.renderObject(keyFinder.first) as RenderRepaintBoundary?;
            if (boundary != null) {
              await _saveRenderBoundary(boundary, name);
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('ScreenshotOverlayService method failed: $e');
      }
      final boundaryFinder = find.byType(RepaintBoundary);
      if (boundaryFinder.evaluate().isNotEmpty) {
        try {
          boundary = tester.renderObject(boundaryFinder.first) as RenderRepaintBoundary?;
          if (boundary != null) {
            await _saveRenderBoundary(boundary, name);
            return;
          }
        } catch (e) {
          debugPrint('RepaintBoundary widget capture failed: $e');
        }
      }
      final appFinder = find.byType(MaterialApp);
      if (appFinder.evaluate().isNotEmpty) {
        final appElement = tester.element(appFinder.first);
        final appRender = appElement.renderObject;
        boundary = findRepaintBoundaryInTree(appRender);
        if (boundary != null) {
          await _saveRenderBoundary(boundary, name);
          return;
        }
      }
      debugPrint('No RenderRepaintBoundary found, screenshot may not be saved locally');
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<String?> _zipInternalScreens() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final srcDir = Directory(p.join(docs.path, 'hemoai_screens'));
      if (!await srcDir.exists()) {
        debugPrint('Zip: source directory does not exist: ${srcDir.path}');
        return null;
      }
      final files = await srcDir.list().where((e) => e is File && e.path.endsWith('.png')).cast<File>().toList();
      if (files.isEmpty) {
        debugPrint('Zip: no PNG files to archive');
        return null;
      }
      final tag = '2025-11-17-android';
      final zipPath = p.join(docs.path, 'hemoai_screens_$tag.zip');
      final archive = Archive();
      for (final f in files) {
        final data = await f.readAsBytes();
        final name = p.basename(f.path);
        archive.addFile(ArchiveFile(name, data.length, data));
      }
      final encoder = ZipEncoder();
      final encoded = encoder.encode(archive);
      final outFile = File(zipPath);
      await outFile.writeAsBytes(encoded!, flush: true);
      debugPrint('ZIP saved: ${outFile.path} (${(encoded.length/1024).toStringAsFixed(1)} KB)');
      if (Platform.isAndroid) {
        // Best-effort: copy to public Downloads for easy adb pull (may fail on newer Androids)
        try {
          final dlZip = File('/sdcard/Download/HemoAI-$tag.zip');
          await dlZip.writeAsBytes(encoded, flush: true);
          debugPrint('ZIP copied to Downloads: ${dlZip.path}');
          debugPrint('↳ Pull with: adb pull "${dlZip.path}" .');
        } catch (e) {
          debugPrint('Downloads copy failed: $e');
        }
        debugPrint('↳ Pull ZIP (internal) with: adb exec-out run-as com.example.hemoai cat "${outFile.path}" > hemoai_screens_${tag}.zip');
      }
      return outFile.path;
    } catch (e) {
      debugPrint('Zip error: $e');
      return null;
    }
  }

  // Toggle theme via ThemeService provider to desired mode
  Future<void> _ensureTheme({required bool dark, required WidgetTester tester}) async {
    try {
      final appFinder = find.byType(MaterialApp);
      if (appFinder.evaluate().isEmpty) return;
      final appElement = tester.element(appFinder.first);
      final themeService = Provider.of<ThemeService>(appElement, listen: false);
      // themeService is ThemeService with properties isDarkMode/toggleTheme
      final bool isDark = themeService.isDarkMode;
      if (isDark != dark) {
        await tester.runAsync(() async {
          await themeService.toggleTheme();
        });
        await tester.pumpAndSettle(const Duration(milliseconds: 400));
      }
    } catch (e) {
      debugPrint('Theme toggle failed or unavailable: $e');
    }
  }

  /// Captures and saves a screenshot to disk
  Future<void> take(String name, WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 200));
      // Try binding-based screenshot first; ignore if plugin unsupported
      try {
        await binding.takeScreenshot(name);
      } catch (e) {
        debugPrint('Binding screenshot not available: $e');
      }
      await _captureAndSaveScreenshot(name, tester);
      debugPrint('✓ Screenshot saved: $name');
    } catch (e) {
      debugPrint('⚠ Screenshot error for $name: $e');
    }
  }

  testWidgets('Store screenshots flow', (tester) async {
    // Launch app in test mode to avoid telemetry noise
    app.main(testMode: true);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Enable screenshot support on Android
    await binding.convertFlutterSurfaceToImage();

    // Ensure logged-in state for navigation
    await tester.runAsync(() async {
      final prefs = await PreferencesService.getInstance();
      await prefs.setUserInfo('Test User', 'test@example.com', '5551234567');
      await prefs.setPersonalInfo(30, 'male', 175, 70);
      await prefs.setOnboardingCompleted(true);
    });
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 1) Dashboard
    await take('01_dashboard', tester);

    // 2) Hemogram Entry (ensure light theme, fallback to route if icon not found)
    await _ensureTheme(dark: false, tester: tester);
    final hemogramIcon = find.byIcon(Icons.bloodtype);
    if (hemogramIcon.evaluate().isNotEmpty) {
      await tester.tap(hemogramIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('02_hemogram_entry', tester);
    } else {
      try {
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.pushNamed('/hemogram_entry');
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await take('02_hemogram_entry', tester);
      } catch (e) {
        debugPrint('Hemogram entry navigation error: $e');
      }
    }

    // 3) Analysis
    try {
      final analysisBtn = find.textContaining(RegExp('Analiz|Analysis', caseSensitive: false));
      if (analysisBtn.evaluate().isNotEmpty) {
        await tester.tap(analysisBtn.first);
      } else {
        // Navigate via route
        final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        nav.pushNamed('/analysis');
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('03_analysis', tester);
    } catch (e) {
      debugPrint('Analysis navigation error: $e');
    }

    // 4) Notifications - Navigate via route
    try {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/notifications');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('04_notifications', tester);
    } catch (e) {
      debugPrint('Notifications navigation error: $e');
    }

    // 5) Reminders - Navigate via route
    try {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/reminders');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('05_reminders', tester);
    } catch (e) {
      debugPrint('Reminders navigation error: $e');
    }

    // 6) Settings - Navigate via route
    try {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/settings');
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      await take('06_settings', tester);
    } catch (e) {
      debugPrint('Settings navigation error: $e');
    }

    // 7) Diet Program (Dark Theme)
    try {
      await _ensureTheme(dark: true, tester: tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/diet_program');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('07_diet_dark', tester);
    } catch (e) {
      debugPrint('Diet (dark) navigation error: $e');
    }

    // Switch to Light for remaining shots
    await _ensureTheme(dark: false, tester: tester);

    // 8) Dashboard (Light)
    try {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('08_dashboard_light', tester);
    } catch (e) {
      debugPrint('Dashboard (light) navigation error: $e');
    }

    // 9) Alternative Medicine (Light)
    try {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/alternative_medicine');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('09_alternative_medicine_light', tester);
    } catch (e) {
      debugPrint('Alternative medicine (light) navigation error: $e');
    }

    // 10) Personal Info (Light)
    try {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/personal_info');
      await tester.pump(const Duration(milliseconds: 700));
      await _captureAndSaveScreenshot('10_personal_info_light', tester);
      debugPrint('✓ Screenshot saved: 10_personal_info_light');
    } catch (e) {
      debugPrint('Personal info (light) navigation error: $e');
    }

    // 11) Health Score (Light) via Advanced Analytics
    try {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/advanced_analytics');
      await tester.pump(const Duration(milliseconds: 700));
      await _captureAndSaveScreenshot('11_health_score_light', tester);
      debugPrint('✓ Screenshot saved: 11_health_score_light');
    } catch (e) {
      debugPrint('Health score (light) navigation error: $e');
    }

    // Create a zip of internal screenshots for reliable pulling
    await tester.runAsync(() async {
      await _zipInternalScreens();
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}
