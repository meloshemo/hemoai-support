import 'package:flutter/foundation.dart';

/// Maps raw OCR text to hemogram test fields used in the database.
/// Returns a partial map; caller should sanitize and persist via DatabaseHelper.insertHemogramTest.
class OcrMappingService {
  static final RegExp _num = RegExp(r'([-+]?\d+(?:[\.,]\d+)?)');

  static Map<String, dynamic> mapHemogramFromText(String text) {
    final lower = text.toLowerCase();
    final Map<String, dynamic> out = {};

    void tryExtract(List<String> keys, String field) {
      for (final k in keys) {
        final idx = lower.indexOf(k);
        if (idx != -1) {
          final tail = lower.substring(idx, (idx + 40).clamp(0, lower.length));
          final m = _num.firstMatch(tail);
          if (m != null) {
            out[field] = _parseNum(m.group(1)!);
            if (kDebugMode) debugPrint('OCR map: $field=${out[field]}');
            return;
          }
        }
      }
    }

    tryExtract(['hb', 'hemoglobin', 'hgb'], 'hemoglobin');
    tryExtract(['wbc', 'leukocyte', 'white blood'], 'leukocyte');
    tryExtract(['rbc', 'erythrocyte', 'red blood'], 'erythrocyte');
    tryExtract(['plt', 'platelet'], 'platelet');
    tryExtract(['mchc'], 'mchc');
    tryExtract(['mch'], 'mch');
    tryExtract(['mcv'], 'mcv');
    tryExtract(['crp'], 'crp');
    tryExtract(['glucose', 'glu'], 'glucose');
    tryExtract(['alt'], 'alt');
    tryExtract(['ast'], 'ast');

    return out;
  }

  static double? _parseNum(String s) {
    final t = s.replaceAll(',', '.');
    return double.tryParse(t);
  }
}


