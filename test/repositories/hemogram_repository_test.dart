import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/repositories/hemogram_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HemogramRepository', () {
    late HemogramRepository hemogramRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      hemogramRepository = HemogramRepository();
    });

    group('Insert Operations', () {
      test('should insert hemogram test', () async {
        final test = {
          'user_id': 1,
          'test_date': DateTime.now().toIso8601String(),
          'wbc': 7.5,
          'rbc': 4.5,
          'hemoglobin': 14.0,
          'hematocrit': 42.0,
          'platelets': 250000,
        };
        
        final testId = await hemogramRepository.insertHemogramTest(test);
        expect(testId, isA<int>());
        expect(testId, greaterThan(0));
      });

      test('should insert test with all required fields', () async {
        final test = {
          'user_id': 1,
          'test_date': DateTime.now().toIso8601String(),
          'wbc': 6.0,
          'rbc': 5.0,
          'hemoglobin': 15.0,
          'hematocrit': 45.0,
          'platelets': 300000,
          'mcv': 90.0,
          'mch': 30.0,
          'mchc': 33.0,
        };
        
        final testId = await hemogramRepository.insertHemogramTest(test);
        expect(testId, greaterThan(0));
      });
    });

    group('Retrieve Operations', () {
      test('should get hemogram tests for user', () async {
        final userId = 1;
        
        // Insert multiple tests
        for (int i = 0; i < 3; i++) {
          await hemogramRepository.insertHemogramTest({
            'user_id': userId,
            'test_date': DateTime.now().subtract(Duration(days: i)).toIso8601String(),
            'wbc': 7.0 + i,
            'rbc': 4.5,
            'hemoglobin': 14.0,
            'hematocrit': 42.0,
            'platelets': 250000,
          });
        }
        
        final tests = await hemogramRepository.getHemogramTests(userId);
        expect(tests, isA<List<Map<String, dynamic>>>());
        expect(tests.length, greaterThanOrEqualTo(3));
      });

      test('should get latest hemogram test', () async {
        final userId = 1;
        
        // Insert multiple tests
        await hemogramRepository.insertHemogramTest({
          'user_id': userId,
          'test_date': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          'wbc': 7.0,
          'rbc': 4.5,
          'hemoglobin': 14.0,
          'hematocrit': 42.0,
          'platelets': 250000,
        });
        
        await hemogramRepository.insertHemogramTest({
          'user_id': userId,
          'test_date': DateTime.now().toIso8601String(),
          'wbc': 8.0,
          'rbc': 4.6,
          'hemoglobin': 14.5,
          'hematocrit': 43.0,
          'platelets': 260000,
        });
        
        final latest = await hemogramRepository.getLatestHemogramTest(userId);
        expect(latest, isNotNull);
        expect(latest!['wbc'], equals(8.0));
      });

      test('should return empty list for user with no tests', () async {
        final tests = await hemogramRepository.getHemogramTests(999);
        expect(tests, isA<List<Map<String, dynamic>>>());
        expect(tests.length, equals(0));
      });

      test('should return null for latest test when no tests exist', () async {
        final latest = await hemogramRepository.getLatestHemogramTest(999);
        expect(latest, isNull);
      });
    });

    group('Data Integrity', () {
      test('should maintain separate tests for different users', () async {
        // Insert test for user 1
        await hemogramRepository.insertHemogramTest({
          'user_id': 1,
          'test_date': DateTime.now().toIso8601String(),
          'wbc': 7.0,
          'rbc': 4.5,
          'hemoglobin': 14.0,
          'hematocrit': 42.0,
          'platelets': 250000,
        });
        
        // Insert test for user 2
        await hemogramRepository.insertHemogramTest({
          'user_id': 2,
          'test_date': DateTime.now().toIso8601String(),
          'wbc': 8.0,
          'rbc': 5.0,
          'hemoglobin': 15.0,
          'hematocrit': 45.0,
          'platelets': 300000,
        });
        
        final user1Tests = await hemogramRepository.getHemogramTests(1);
        final user2Tests = await hemogramRepository.getHemogramTests(2);
        
        expect(user1Tests.length, greaterThanOrEqualTo(1));
        expect(user2Tests.length, greaterThanOrEqualTo(1));
        expect(user1Tests[0]['user_id'], equals(1));
        expect(user2Tests[0]['user_id'], equals(2));
      });
    });
  });
}

