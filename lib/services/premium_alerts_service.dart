import 'package:flutter/material.dart';

class PremiumAlertsService {
  /// Returns smart alerts and next test date recommendation based on latest test
  static PremiumAlertResult analyzeLatest(Map<String, dynamic>? latest) {
    if (latest == null) return PremiumAlertResult(alerts: [], nextTestDate: null);

    final double? hb = _num(latest['hemoglobin']);
    final double? crp = _num(latest['crp']);
    final double? glucose = _num(latest['glucose']);

    final List<PremiumAlert> alerts = [];

    void add(String key, String message, Color color, {double? value, double? targetMin, double? targetMax}) {
      alerts.add(PremiumAlert(key: key, message: message, color: color, value: value, targetMin: targetMin, targetMax: targetMax));
    }

    // Hemoglobin
    if (hb != null) {
      if (hb < 12) {
        add('hb_low', 'Hemoglobin below normal', Colors.orange, value: hb, targetMin: 12, targetMax: 16);
      } else if (hb > 16.5) {
        add('hb_high', 'Hemoglobin above normal', Colors.orange, value: hb, targetMin: 12, targetMax: 16.5);
      }
    }
    // CRP
    if (crp != null && crp > 5) {
      add('crp_high', 'CRP indicates inflammation', Colors.red, value: crp, targetMin: 0, targetMax: 5);
    }
    // Glucose
    if (glucose != null && glucose >= 126) {
      add('glucose_high', 'Fasting glucose in diabetic range', Colors.red, value: glucose, targetMin: 70, targetMax: 99);
    }

    DateTime? nextTest;
    if (alerts.any((a) => a.color == Colors.red)) {
      nextTest = DateTime.now().add(const Duration(days: 7));
    } else if (alerts.isNotEmpty) {
      nextTest = DateTime.now().add(const Duration(days: 30));
    } else {
      nextTest = DateTime.now().add(const Duration(days: 90));
    }

    return PremiumAlertResult(alerts: alerts, nextTestDate: nextTest);
  }

  static double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class PremiumAlertResult {
  final List<PremiumAlert> alerts;
  final DateTime? nextTestDate;
  const PremiumAlertResult({required this.alerts, required this.nextTestDate});
}

class PremiumAlert {
  final String key;
  final String message;
  final Color color;
  final double? value;
  final double? targetMin;
  final double? targetMax;
  const PremiumAlert({required this.key, required this.message, required this.color, this.value, this.targetMin, this.targetMax});

  String? get distanceToTarget {
    if (value == null) return null;
    if (targetMin != null && value! < targetMin!) {
      return (targetMin! - value!).toStringAsFixed(1);
    }
    if (targetMax != null && value! > targetMax!) {
      return (value! - targetMax!).toStringAsFixed(1);
    }
    return null;
  }
}


