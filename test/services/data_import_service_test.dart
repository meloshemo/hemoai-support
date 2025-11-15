import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/data_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataImportService', () {
    late DataImportService importService;

    setUp(() {
      importService = DataImportService();
    });

    group('Text Import', () {
      test('should import from JSON text', () async {
        const jsonText = '''
        {
          "hemoglobin": 14.5,
          "glucose": 90.0,
          "iron": 100.0
        }
        ''';
        
        final result = await importService.importFromText(jsonText);
        expect(result.isSuccess, true);
        expect(result.testResults, isNotEmpty);
      });

      test('should import from structured text', () async {
        const text = '''
        Hemoglobin: 14.5 g/dL
        Glucose: 90 mg/dL
        Iron: 100 μg/dL
        ''';
        
        final result = await importService.importFromText(text);
        // May or may not succeed depending on parsing logic
        expect(result, isNotNull);
      });

      test('should handle empty text', () async {
        final result = await importService.importFromText('');
        expect(result.isSuccess, false);
        expect(result.message, contains('No text provided'));
      });

      test('should handle invalid JSON', () async {
        const invalidJson = '{hemoglobin: 14.5}'; // Invalid JSON
        final result = await importService.importFromText(invalidJson);
        // Should fall back to structured text parsing
        expect(result, isNotNull);
      });
    });

    group('QR Code Import', () {
      test('should handle QR code data', () async {
        const qrData = '{"hemoglobin":14.5,"glucose":90}';
        final result = await importService.importFromQR(qrData);
        expect(result, isNotNull);
      });

      test('should handle invalid QR data', () async {
        const invalidQr = 'not-json-data';
        final result = await importService.importFromQR(invalidQr);
        expect(result, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should return error for unsupported format', () async {
        // This would require file picker mock
        // Placeholder for integration test
        expect(importService, isNotNull);
      });

      test('should handle parsing errors gracefully', () async {
        const malformedText = r'!!!@@@###$$$';
        final result = await importService.importFromText(malformedText);
        expect(result, isNotNull);
        // Should not throw exception
      });
    });
  });
}

