import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:hemoai/main.dart' as app;
import 'package:hemoai/services/preferences_service.dart';
import 'package:hemoai/services/screenshot_overlay_service.dart';

/// Drives core screens and captures store screenshots.
/// Run:
///   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshot_flow_test.dart -d <device>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;

  /// Captures and saves a screenshot to disk
  Future<void> take(String name, WidgetTester tester) async {
    try {
      // Wait for UI to settle completely
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      
      // Use integration test binding screenshot (for CI/CD compatibility)
      await binding.takeScreenshot(name);
      
      // Also manually capture and save to ensure it's saved locally
      await _captureAndSaveScreenshot(name, tester);
      
      debugPrint('✓ Screenshot saved: $name');
    } catch (e) {
      debugPrint('⚠ Screenshot error for $name: $e');
      // Continue even if screenshot fails
    }
  }

  /// Manually captures the screen and saves to file using the most reliable method
  Future<void> _captureAndSaveScreenshot(String name, WidgetTester tester) async {
    try {
      // Additional wait for any final animations
      await tester.pump(const Duration(milliseconds: 300));
      
      RenderRepaintBoundary? boundary;
      
      // Method 1: Use ScreenshotOverlayService's RepaintBoundary key (most reliable)
      try {
        final appFinder = find.byType(MaterialApp);
        if (appFinder.evaluate().isNotEmpty) {
          final appElement = tester.element(appFinder.first);
          final screenshotService = Provider.of<ScreenshotOverlayService>(appElement, listen: false);
          final key = screenshotService.repaintBoundaryKey;
          
          // Find widget by key
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

      // Method 2: Look for any RepaintBoundary widgets
      final boundaryFinder = find.byType(RepaintBoundary);
      if (boundaryFinder.evaluate().isNotEmpty) {
        try {
          // Try the first one (usually the main one from main.dart)
          boundary = tester.renderObject(boundaryFinder.first) as RenderRepaintBoundary?;
          if (boundary != null) {
            await _saveRenderBoundary(boundary, name);
            return;
          }
        } catch (e) {
          debugPrint('RepaintBoundary widget capture failed: $e');
        }
      }

      // Method 3: Traverse render tree from MaterialApp
      final appFinder = find.byType(MaterialApp);
      if (appFinder.evaluate().isNotEmpty) {
        final appElement = tester.element(appFinder.first);
        final appRender = appElement.renderObject;
        boundary = _findRepaintBoundaryInTree(appRender);
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

  /// Recursively finds a RenderRepaintBoundary in the render tree
  RenderRepaintBoundary? _findRepaintBoundaryInTree(RenderObject? root) {
    if (root == null) return null;
    
    if (root is RenderRepaintBoundary) {
      return root;
    }
    
    // Check children
    RenderObject? child = root.firstChild;
    while (child != null) {
      final result = _findRepaintBoundaryInTree(child);
      if (result != null) return result;
      child = child.nextSibling;
    }
    
    return null;
  }

  /// Saves a RenderRepaintBoundary as PNG file
  Future<void> _saveRenderBoundary(RenderRepaintBoundary boundary, String name) async {
    try {
      // Capture at high resolution (3x for retina displays)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        debugPrint('Failed to convert image to byte data');
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      
      // Ensure screenshots directory exists
      final dir = Directory('integration_test/screenshots');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Save the file
      final file = File('${dir.path}/$name.png');
      await file.writeAsBytes(bytes, flush: true);
      
      final fileSizeKB = (bytes.length / 1024).toStringAsFixed(2);
      debugPrint('  → Saved: ${file.path} (${fileSizeKB} KB)');
    } catch (e) {
      debugPrint('Save error: $e');
      rethrow;
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

    // 2) Hemogram Entry
    final hemogramIcon = find.byIcon(Icons.bloodtype);
    if (hemogramIcon.evaluate().isNotEmpty) {
      await tester.tap(hemogramIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await take('02_hemogram_entry', tester);
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
  }, timeout: const Timeout(Duration(minutes: 2)));
}
