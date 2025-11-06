import 'dart:math';
import 'database_helper.dart';
import 'preferences_service.dart';
import 'localization_service.dart';

enum TrendDirection { up, down, stable }

class ParamTrend {
  final String key;
  final TrendDirection direction;
  final double percentChange; // -100..+infinity
  final int sampleCount;

  const ParamTrend({
    required this.key,
    required this.direction,
    required this.percentChange,
    required this.sampleCount,
  });
}

class ParameterFlag {
  final String key; // canonical marker key
  final String direction; // 'low' | 'high' | 'very_high'
  final double severity; // relative deviation magnitude (higher = more severe)

  const ParameterFlag({
    required this.key,
    required this.direction,
    required this.severity,
  });
}

class AnalysisResult {
  final Map<String, Map<String, double>> referenceRanges;
  final double riskScore; // 0..100
  final String riskLabel; // low|medium|high|very_high
  final List<ParameterFlag> flags; // ordered by severity desc
  final List<ParamTrend> trends; // last 6 months
  final List<String> recommendations; // already localized strings
  final String summary; // short localized assessment

  const AnalysisResult({
    required this.referenceRanges,
    required this.riskScore,
    required this.riskLabel,
    required this.flags,
    required this.trends,
    required this.recommendations,
    required this.summary,
  });
}

class AnalysisService {
  // Baseline adult reference ranges; will be adjusted by age/gender when applicable
  static final Map<String, Map<String, double>> baseRanges = {
    'hemoglobin': {'min': 12.0, 'max': 17.0}, // will be adjusted by sex
    'glucose': {'min': 70.0, 'max': 100.0},
    'calcium': {'min': 8.6, 'max': 10.2},
    'sodium': {'min': 135.0, 'max': 145.0},
    'potassium': {'min': 3.5, 'max': 5.1},
    'chloride': {'min': 98.0, 'max': 107.0},
    'alt': {'min': 7.0, 'max': 56.0},
    'ast': {'min': 10.0, 'max': 40.0},
    'ggt': {'min': 9.0, 'max': 48.0},
    'total_bilirubin': {'min': 0.1, 'max': 1.2},
    'direct_bilirubin': {'min': 0.0, 'max': 0.3},
    'crp': {'min': 0.0, 'max': 5.0},
    'iron': {'min': 60.0, 'max': 170.0},
    'uibc': {'min': 110.0, 'max': 370.0},
    'tibc': {'min': 240.0, 'max': 450.0},
    'tsh': {'min': 0.4, 'max': 4.0},
    'free_t3': {'min': 2.0, 'max': 4.4},
    'free_t4': {'min': 0.8, 'max': 1.8},
    'vitamin_d3': {'min': 20.0, 'max': 50.0},
    'vitamin_b12': {'min': 200.0, 'max': 900.0},
  };

  Map<String, Map<String, double>> _adjustRangesFor(int? age, String? gender) {
    // Copy base
    final ranges = baseRanges.map((k, v) => MapEntry(k, {...v}));
    final g = (gender ?? '').toLowerCase();
    // Sex-specific: Hemoglobin
    if (g.contains('male') || g.contains('erkek')) {
      ranges['hemoglobin'] = {'min': 13.5, 'max': 17.5};
    } else if (g.contains('female') || g.contains('kadin')) {
      ranges['hemoglobin'] = {'min': 12.0, 'max': 16.0};
    }
    // Age adjustments (simple heuristics to avoid overfitting):
    if (age != null) {
      if (age < 18) {
        // Teens: slightly lower Hb upper bound; WBC not in our set, leave as-is
        ranges['hemoglobin'] = {'min': 11.5, 'max': 15.5};
      } else if (age > 65) {
        // Older adults: consider Vitamin D desirable up to 60
        ranges['vitamin_d3'] = {'min': 20.0, 'max': 60.0};
      }
    }
    return ranges;
  }

  Future<AnalysisResult> analyze({
    required int userId,
    required Map<String, double> currentValues,
    DateTime? now,
  }) async {
    final loc = LocalizationService();
    final prefs = await PreferencesService.getInstance();
    final info = await prefs.getUserInfoAsync();
    final age = info?['age'] as int?;
    final gender = info?['gender'] as String?;
    final ranges = _adjustRangesFor(age, gender);

  // Fetch last 6 months history
    final db = DatabaseHelper.instance;
    final tests = await db.getHemogramTestsByUser(userId);
  final meds = await db.getMedications(userId);
    final nowDt = now ?? DateTime.now();
    final sixMonthsAgo = DateTime(nowDt.year, nowDt.month - 6, nowDt.day);
    final recent = tests.where((t) {
      final s = t['test_date'] as String?;
      final d = DateTime.tryParse(s ?? '');
      return d != null && d.isAfter(sixMonthsAgo);
    }).toList();

    // Build series per parameter
    final Map<String, List<(DateTime, double)>> series = {};
    void addPoint(String key, dynamic v, DateTime d) {
      if (v == null) return;
      final val = (v as num).toDouble();
      (series[key] ??= []).add((d, val));
    }
    for (final row in recent) {
      final d = DateTime.tryParse((row['test_date'] as String?) ?? '');
      if (d == null) continue;
      for (final entry in ranges.keys) {
        // Map canonical keys to db columns if needed
        final dbVal = _tryDbValue(entry, row);
        addPoint(entry, dbVal, d);
      }
    }
    // Include current values as the latest point
    for (final e in currentValues.entries) {
      (series[e.key] ??= []).add((nowDt, e.value));
    }

    // Compute trends
    final List<ParamTrend> trends = [];
    for (final entry in series.entries) {
      final points = entry.value..sort((a, b) => a.$1.compareTo(b.$1));
      if (points.length < 2) continue;
      final first = points.first.$2;
      final last = points.last.$2;
      if (first == 0) continue;
      final pct = ((last - first) / first) * 100.0;
      final dir = pct.abs() < 5.0
          ? TrendDirection.stable
          : (pct > 0 ? TrendDirection.up : TrendDirection.down);
      trends.add(ParamTrend(
        key: entry.key,
        direction: dir,
        percentChange: pct,
        sampleCount: points.length,
      ));
    }

    // Flags and risk score
    final List<ParameterFlag> flags = [];
    int abnormal = 0;
    int bonus = 0;
    currentValues.forEach((key, value) {
      final range = ranges[key];
      if (range == null) return;
      if (value < range['min']! || value > range['max']!) {
        abnormal += 1;
        if (value < range['min']!) {
          final diff = (range['min']! - value) / max(range['min']!, 0.0001);
          flags.add(ParameterFlag(key: key, direction: 'low', severity: diff));
        } else if (value > range['max']!) {
          final diff = (value - range['max']!) / max(range['max']!, 0.0001);
          final isVery = value > range['max']! * 1.5;
          flags.add(ParameterFlag(key: key, direction: isVery ? 'very_high' : 'high', severity: isVery ? diff + 0.5 : diff));
          if (isVery) bonus += 20;
        }
      }
    });
    flags.sort((a, b) => b.severity.compareTo(a.severity));
    double score = (abnormal * 15 + bonus).toDouble().clamp(0, 100);
    final riskLabel = score <= 33
        ? 'low'
        : (score <= 66 ? 'medium' : (flags.any((f) => f.direction == 'very_high') ? 'very_high' : 'high'));

    // Summary
    final summary = abnormal == 0
        ? loc.getString('overall_assessment_normal')
        : (abnormal <= 2 ? loc.getString('overall_assessment_some_abnormal') : loc.getString('overall_assessment_many_abnormal'));

    // Recommendations (personalized)
  final recs = _buildRecommendations(currentValues, ranges, trends, meds);

    return AnalysisResult(
      referenceRanges: ranges,
      riskScore: score,
      riskLabel: riskLabel,
      flags: flags,
      trends: trends,
      recommendations: recs,
      summary: summary,
    );
  }

  dynamic _tryDbValue(String canonicalKey, Map<String, dynamic> row) {
    // Map canonical markers to DB columns used in hemogram_tests
    switch (canonicalKey) {
      case 'white_blood_cells':
        return row['leukocyte'];
      case 'red_blood_cells':
        return row['erythrocyte'];
      case 'platelets':
        return row['platelet'];
      default:
        return row[canonicalKey];
    }
  }

  List<String> _buildRecommendations(
    Map<String, double> values,
    Map<String, Map<String, double>> ranges,
    List<ParamTrend> trends,
    List<Map<String, dynamic>> medications,
  ) {
    final loc = LocalizationService();
    final List<String> out = [];

    void addIf(bool cond, String key) {
      if (cond) out.add(loc.getString(key));
    }

    double? v(String k) => values[k];
    bool above(String k) => v(k) != null && ranges[k] != null && v(k)! > ranges[k]!['max']!;
    bool below(String k) => v(k) != null && ranges[k] != null && v(k)! < ranges[k]!['min']!;

    // Concrete rules
    addIf(below('hemoglobin'), 'hemoglobin_low_recommendation');
    addIf(below('iron'), 'iron_low_recommendation');
    addIf(above('glucose'), 'glucose_high_recommendation');
    addIf(below('vitamin_d3'), 'vitamin_d3_low_recommendation');
    addIf(below('tsh') || above('tsh'), 'tsh_abnormal_recommendation');

    // Water intake suggestion if sodium or CRP elevated
    addIf(above('sodium') || above('crp'), 'suggestion_increase_water_intake');

    // Simple medication alerts for iron deficiency/excess
    final hasIronMed = medications.any((m) {
      final name = (m['name'] as String? ?? '').toLowerCase();
      return name.contains('iron') || name.contains('ferrous') || name.contains('demir');
    });
    if (below('iron') && !hasIronMed) {
      out.add(loc.getString('suggestion_consider_iron_supplement'));
    }
    if (above('iron') && hasIronMed) {
      out.add(loc.getString('medication_check_iron_dosage'));
    }

    // Thyroid trends: rising TSH or falling free T4 -> suggest follow-up
  final tshTrend = _firstWhereOrNull(trends, (t) => t.key == 'tsh');
  final ft4Trend = _firstWhereOrNull(trends, (t) => t.key == 'free_t4');
    if (tshTrend != null && tshTrend.direction == TrendDirection.up && tshTrend.percentChange.abs() >= 10) {
      out.add(loc.getString('consider_follow_up'));
    }
    if (ft4Trend != null && ft4Trend.direction == TrendDirection.down && ft4Trend.percentChange.abs() >= 10) {
      out.add(loc.getString('consider_follow_up'));
    }

    // If nothing specific, provide defaults; else add doctor follow-up
    if (out.isEmpty) {
      out.addAll([
        loc.getString('recommendation_default_1'),
        loc.getString('recommendation_default_2'),
        loc.getString('recommendation_default_3'),
      ]);
    } else {
      out.add(loc.getString('recommendation_follow_up_doctor'));
    }

    return out;
  }

  T? _firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }
}
