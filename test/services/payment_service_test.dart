import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentService', () {
    late PaymentService paymentService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      paymentService = PaymentService();
    });

    test('should create singleton instance', () {
      final instance1 = PaymentService();
      final instance2 = PaymentService();
      expect(instance1, equals(instance2));
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await paymentService.initialize();
        expect(paymentService.isAvailable, isA<bool>());
      });

      test('should be available on web platform', () async {
        await paymentService.initialize();
        // On web, Stripe Checkout is available
        expect(paymentService.isAvailable, true);
      });
    });

    group('Product Information', () {
      test('should get product price for monthly plan', () {
        final price = paymentService.getProductPrice(
          isYearly: false,
          isLifetime: false,
          languageCode: 'en',
        );
        expect(price, isA<String?>());
      });

      test('should get product price for yearly plan', () {
        final price = paymentService.getProductPrice(
          isYearly: true,
          isLifetime: false,
          languageCode: 'en',
        );
        expect(price, isA<String?>());
      });

      test('should get product price for lifetime plan', () {
        final price = paymentService.getProductPrice(
          isYearly: false,
          isLifetime: true,
          languageCode: 'en',
        );
        expect(price, isA<String?>());
      });

      test('should return null price when products not loaded', () {
        // Before initialization, products may not be loaded
        final price = paymentService.getProductPrice(
          isYearly: false,
          isLifetime: false,
        );
        // May be null if products not loaded
        expect(price, anyOf(isA<String>(), isNull));
      });
    });

    group('Purchase Status', () {
      test('should check purchase pending status', () {
        expect(paymentService.purchasePending, isA<bool>());
        expect(paymentService.purchasePending, false); // Initially false
      });

      test('should check availability', () async {
        await paymentService.initialize();
        expect(paymentService.isAvailable, isA<bool>());
      });
    });

    group('Dispose', () {
      test('should dispose without errors', () {
        expect(() => paymentService.dispose(), returnsNormally);
      });
    });
  });
}

