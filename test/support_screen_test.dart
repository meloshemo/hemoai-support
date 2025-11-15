import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hemoai/services/localization_service.dart';
import 'package:hemoai/services/premium_service.dart';
import 'package:hemoai/screens/support_screen.dart';

void main() {
  testWidgets('SupportScreen builds and displays sections', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocalizationService()..initialize()),
          ChangeNotifierProvider(create: (_) => PremiumService()..initialize()),
        ],
        child: const MaterialApp(
          home: SupportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

  // Initial cards (lazy list) should build at least one
  expect(find.byType(Card), findsWidgets);
  // Scroll to force building remaining sections
  await tester.drag(find.byType(ListView), const Offset(0, -1000));
  await tester.pumpAndSettle();
  // Verify that later section (Refund Policy) appears
  expect(find.textContaining('Refund').evaluate().isNotEmpty || find.textContaining('İade').evaluate().isNotEmpty, true);
  });
}
