import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/diet_program_service.dart';

void main() {
  group('DietProgramService', () {
    late DietProgramService service;

    setUp(() {
      service = DietProgramService();
    });

    test('returns balanced program when no abnormalities', () {
      final programs = service.generate(values: {});
      expect(programs, isNotEmpty);
      expect(programs.first.titleKey, 'diet_balanced_title');
    });

    test('high glucose triggers glucose control diet', () {
      final programs = service.generate(values: {
        'glucose': 110.0,
      });
      expect(
        programs.any((p) => p.titleKey == 'diet_glucose_control_title'),
        isTrue,
      );
    });

    test('elevated ALT triggers liver support diet', () {
      final programs = service.generate(values: {
        'alt': 65.0,
      });
      expect(
        programs.any((p) => p.titleKey == 'diet_liver_support_title'),
        isTrue,
      );
    });

    test('elevated CRP triggers anti-inflammatory diet', () {
      final programs = service.generate(values: {
        'crp': 10.0,
      });
      expect(
        programs.any((p) => p.titleKey == 'diet_crp_antiinflam_title'),
        isTrue,
      );
    });

    test('thyroid imbalance triggers thyroid support diet', () {
      final programs = service.generate(values: {
        'tsh': 8.0,
      });
      expect(
        programs.any((p) => p.titleKey == 'diet_thyroid_support_title'),
        isTrue,
      );
    });

    test('low vitamin D3 triggers vitamin D support diet', () {
      final programs = service.generate(values: {
        'vitamin_d3': 12.0,
      });
      expect(
        programs.any((p) => p.titleKey == 'diet_vitd_support_title'),
        isTrue,
      );
    });

    test('electrolyte imbalance triggers electrolyte balance diet', () {
      final programs = service.generate(values: {
        'sodium': 150.0,
      });
      expect(
        programs.any((p) => p.titleKey == 'diet_electrolyte_balance_title'),
        isTrue,
      );
    });

    test('low calcium triggers calcium support diet', () {
      final programs = service.generate(values: {
        'calcium': 8.0,
      });
      expect(
        programs.any((p) => p.titleKey == 'diet_calcium_support_title'),
        isTrue,
      );
    });
  });
}
