import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/analysis_service.dart';
import 'package:hemoai/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalysisService', () {
    late AnalysisService analysisService;
    late LocalizationService localizationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      analysisService = AnalysisService();
      localizationService = LocalizationService();
      await localizationService.initialize();
    });

    group('Reference Ranges', () {
      test('should have base reference ranges', () {
        expect(AnalysisService.baseRanges, isNotEmpty);
        expect(AnalysisService.baseRanges.containsKey('hemoglobin'), true);
        expect(AnalysisService.baseRanges.containsKey('glucose'), true);
        expect(AnalysisService.baseRanges.containsKey('iron'), true);
      });

      test('should have valid range values', () {
        final hbRange = AnalysisService.baseRanges['hemoglobin'];
        expect(hbRange, isNotNull);
        expect(hbRange!['min'], lessThan(hbRange['max']!));
        
        final glucoseRange = AnalysisService.baseRanges['glucose'];
        expect(glucoseRange, isNotNull);
        expect(glucoseRange!['min'], lessThan(glucoseRange['max']!));
      });

      test('should have ranges for all common parameters', () {
        final commonParams = ['hemoglobin', 'glucose', 'iron', 'vitamin_d3', 'tsh'];
        for (final param in commonParams) {
          expect(AnalysisService.baseRanges.containsKey(param), true,
            reason: '$param should have reference range');
        }
      });
    });

    group('Analysis', () {
      test('should analyze normal values', () async {
        final values = {
          'hemoglobin': 14.0,
          'glucose': 85.0,
          'iron': 100.0,
        };
        
        final result = await analysisService.analyze(
          values: values,
          userId: 1,
        );
        
        expect(result, isNotNull);
        expect(result.riskScore, lessThan(50)); // Low risk for normal values
        expect(result.riskLabel, isA<String>());
        expect(result.summary, isNotEmpty);
      });

      test('should flag high hemoglobin', () async {
        final values = {
          'hemoglobin': 18.0, // High (above max 17.0)
          'glucose': 85.0,
        };
        
        final result = await analysisService.analyze(
          values: values,
          userId: 1,
        );
        
        expect(result.flags, isNotEmpty);
        final hbFlag = result.flags.firstWhere(
          (f) => f.key == 'hemoglobin',
          orElse: () => throw Exception('Hemoglobin flag not found'),
        );
        expect(hbFlag.direction, contains('high'));
      });

      test('should flag low iron', () async {
        final values = {
          'iron': 30.0, // Low (below min 60.0)
          'hemoglobin': 14.0,
        };
        
        final result = await analysisService.analyze(
          values: values,
          userId: 1,
        );
        
        expect(result.flags, isNotEmpty);
        final ironFlag = result.flags.firstWhere(
          (f) => f.key == 'iron',
          orElse: () => throw Exception('Iron flag not found'),
        );
        expect(ironFlag.direction, 'low');
      });

      test('should calculate risk score', () async {
        final normalValues = {
          'hemoglobin': 14.0,
          'glucose': 85.0,
          'iron': 100.0,
        };
        
        final normalResult = await analysisService.analyze(
          values: normalValues,
          userId: 1,
        );
        
        final abnormalValues = {
          'hemoglobin': 18.0, // High
          'glucose': 120.0, // High
          'iron': 30.0, // Low
        };
        
        final abnormalResult = await analysisService.analyze(
          values: abnormalValues,
          userId: 1,
        );
        
        expect(abnormalResult.riskScore, greaterThan(normalResult.riskScore));
      });

      test('should generate recommendations', () async {
        final values = {
          'iron': 30.0, // Low iron
          'vitamin_d3': 15.0, // Low vitamin D
        };
        
        final result = await analysisService.analyze(
          values: values,
          userId: 1,
        );
        
        expect(result.recommendations, isNotEmpty);
        expect(result.recommendations.length, greaterThan(0));
      });

      test('should include reference ranges in result', () async {
        final values = {'hemoglobin': 14.0};
        final result = await analysisService.analyze(
          values: values,
          userId: 1,
        );
        
        expect(result.referenceRanges, isNotEmpty);
        expect(result.referenceRanges.containsKey('hemoglobin'), true);
      });
    });

    group('Trend Analysis', () {
      test('should include trends in analysis result', () async {
        final values = {'hemoglobin': 14.0};
        final result = await analysisService.analyze(
          values: values,
          userId: 1,
        );
        
        expect(result.trends, isA<List<ParamTrend>>());
        // Trends may be empty if no history, which is valid
      });

      test('should handle empty history gracefully', () async {
        final values = {'hemoglobin': 14.0};
        final result = await analysisService.analyze(
          values: values,
          userId: 999, // Non-existent user
        );
        
        expect(result, isNotNull);
        expect(result.trends, isA<List<ParamTrend>>());
      });
    });
  });
}

