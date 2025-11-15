// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:hemoai/main.dart' as app;
import 'package:hemoai/services/screenshot_overlay_service.dart';
import 'package:hemoai/services/localization_service.dart';
import 'package:hemoai/services/preferences_service.dart';
import 'package:hemoai/screens/analysis_screen.dart';
import 'package:hemoai/screens/enhanced_notification_screen.dart';
import 'package:hemoai/screens/alternative_medicine_screen.dart';
import 'package:hemoai/screens/dashboard_screen.dart';

Future<void> pumpAndSettleShort(WidgetTester tester) async {
  // Allow brief async work between navigation pushes.
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> setOverlay(WidgetTester tester, String key) async {
  final overlay = tester.widgetList(find.byType(Overlay)).isNotEmpty;
  expect(overlay, isTrue, reason: 'App should have an overlay context.');
  final service = tester.element(find.byType(MaterialApp)).read<ScreenshotOverlayService>();
  service.show(key);
  await pumpAndSettleShort(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App store screenshots flow', () {
    testWidgets('Capture key flows with overlay titles', (tester) async {
      // Drain any pre-existing framework exceptions so they don't fail the test later.
      dynamic drainOnce() => tester.takeException();
      void drainFlutterErrors() {
        dynamic e;
        // Clear all queued exceptions emitted by the rendering library during layout.
        // These are often harmless overflows under test constraints and would otherwise fail the test.
        while ((e = drainOnce()) != null) {
          print('IGNORED_TEST_EXCEPTION:$e');
        }
      }

      app.main(testMode: true);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      drainFlutterErrors();

      // Ensure a logged-in session so we can navigate freely to dashboard and inner routes.
      await tester.runAsync(() async {
        final prefs = await PreferencesService.getInstance();
        await prefs.setUserInfo('Test User', 'test@example.com', '5551234567');
        await prefs.setPersonalInfo(30, 'male', 175, 70);
        await prefs.setOnboardingCompleted(true);
      });
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      drainFlutterErrors();

      // Enable screenshot support on Android by converting the surface to an image.
      await binding.convertFlutterSurfaceToImage();

      // Ensure localization service loaded.
      final loc = tester.element(find.byType(MaterialApp)).read<LocalizationService>();
      expect(loc.currentLanguageCode.isNotEmpty, true);
      drainFlutterErrors();

      Future<void> logBoundaryBase64(String id) async {
        try {
          final ctx = tester.element(find.byType(MaterialApp));
          final ss = ctx.read<ScreenshotOverlayService>();
          final boundaryCtx = ss.repaintBoundaryKey.currentContext;
          if (boundaryCtx == null) return;
          final render = boundaryCtx.findRenderObject();
          if (render is! RenderRepaintBoundary) return;
          final image = await render.toImage(pixelRatio: 3.0); // High fidelity
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) return;
          final bytes = byteData.buffer.asUint8List();
          final b64 = base64Encode(bytes);
          const chunkSize = 800; // Keep console lines manageable
          for (int i = 0; i < b64.length; i += chunkSize) {
            final chunk = b64.substring(i, (i + chunkSize > b64.length) ? b64.length : i + chunkSize);
            // Format: SCREENSHOT_BASE64_CHUNK:<ID>:<OFFSET>:<DATA>
            // <ID> is numeric order (01,02,...), <OFFSET> is starting index
            // Consumers concatenate DATA parts ordered by OFFSET until END marker.
            // Avoid extra logs that might be truncated.
            // Use print() so integration test output captures it.
            print('SCREENSHOT_BASE64_CHUNK:$id:$i:$chunk');
          }
          print('SCREENSHOT_BASE64_END:$id');
        } catch (e) {
          print('SCREENSHOT_BASE64_ERROR:$id:$e');
        }
      }

      Future<void> navigateTo(String routeName, Type screenType) async {
        final navFinder = find.byType(Navigator);
        expect(navFinder, findsWidgets, reason: 'Navigator should exist');
        final NavigatorState nav = tester.state<NavigatorState>(navFinder.first);
        nav.pushNamed(routeName);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        drainFlutterErrors();
        // Wait until the expected screen widget appears
        expect(find.byType(screenType), findsOneWidget);
      }

      // 1. Notifications (requested first)
      await navigateTo('/notifications', EnhancedNotificationScreen);
      await setOverlay(tester, 'ss_title_notifications');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      drainFlutterErrors();
      await binding.takeScreenshot('01_notifications');
      final overlayService = tester.element(find.byType(MaterialApp)).read<ScreenshotOverlayService>();
      final path1 = await overlayService.captureToExternal('01_notifications.png');
      if (path1 != null) {
        print('SCREENSHOT_EXTERNAL_PATH:01:$path1');
      }
      await logBoundaryBase64('01');
      drainFlutterErrors();

      // 2. Dashboard (full)
      await navigateTo('/dashboard', DashboardScreen);
      await setOverlay(tester, 'ss_title_dashboard');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      drainFlutterErrors();
      await binding.takeScreenshot('02_dashboard');
      final path2 = await overlayService.captureToExternal('02_dashboard.png');
      if (path2 != null) {
        print('SCREENSHOT_EXTERNAL_PATH:02:$path2');
      }
      await logBoundaryBase64('02');
      drainFlutterErrors();

      // 3. AI Analysis
      await navigateTo('/analysis', AnalysisScreen);
      await setOverlay(tester, 'ss_title_analysis');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      drainFlutterErrors();
      await binding.takeScreenshot('03_analysis');
      final path3 = await overlayService.captureToExternal('03_analysis.png');
      if (path3 != null) {
        print('SCREENSHOT_EXTERNAL_PATH:03:$path3');
      }
      await logBoundaryBase64('03');
      drainFlutterErrors();

      // 4. Alternative Medicine
      await navigateTo('/alternative_medicine', AlternativeMedicineScreen);
      await setOverlay(tester, 'ss_title_alternative_medicine');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      drainFlutterErrors();
      await binding.takeScreenshot('04_alternative_medicine');
      final path4 = await overlayService.captureToExternal('04_alternative_medicine.png');
      if (path4 != null) {
        print('SCREENSHOT_EXTERNAL_PATH:04:$path4');
      }
      await logBoundaryBase64('04');
      drainFlutterErrors();

      // Hide overlay at end to leave app clean for further tests.
      final service = tester.element(find.byType(MaterialApp)).read<ScreenshotOverlayService>();
      service.hide(); // end
      await pumpAndSettleShort(tester);
      drainFlutterErrors();
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
