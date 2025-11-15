import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/repositories/hemogram_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HemogramRepository', () {
    late HemogramRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = HemogramRepository();
    });

    test('saveHemogram persists active record', () async {
      final id = await repository.saveHemogram(
        userId: 1,
        values: {
          'hemoglobin': 14.0,
          'leukocyte': 7.8,
          'platelet': 250000,
        },
      );

      expect(id, greaterThan(0));

      final active = await repository.getActiveHemogram(1);
      expect(active, isNotNull);
      expect(active!.isActive, isTrue);
      expect(active.values['hemoglobin'], equals(14.0));
    });

    test('latest save archives previous active record', () async {
      await repository.saveHemogram(
        userId: 5,
        values: {
          'hemoglobin': 12.5,
          'leukocyte': 6.4,
        },
        testDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      await repository.saveHemogram(
        userId: 5,
        values: {
          'hemoglobin': 13.2,
          'leukocyte': 7.1,
        },
      );

      final history = await repository.getHemogramHistory(5);
      expect(history.length, equals(2));
      expect(history.first.isActive, isTrue);
      expect(history.last.status, equals('archived'));
      expect(history.last.archivedAt, isNotNull);
    });

    test('histories are isolated per user', () async {
      await repository.saveHemogram(
        userId: 7,
        values: {
          'hemoglobin': 13.0,
          'leukocyte': 6.0,
        },
      );

      await repository.saveHemogram(
        userId: 11,
        values: {
          'hemoglobin': 15.0,
          'leukocyte': 8.2,
        },
      );

      final user7History = await repository.getHemogramHistory(7);
      final user11History = await repository.getHemogramHistory(11);

      expect(user7History, hasLength(1));
      expect(user11History, hasLength(1));
      expect(user7History.first.userId, equals(7));
      expect(user11History.first.userId, equals(11));
    });

    test('getActiveHemogram returns null when user has no tests', () async {
      final active = await repository.getActiveHemogram(999);
      expect(active, isNull);
    });
  });
}
