import 'package:flutter/foundation.dart';
import 'localization_service.dart';
import '../services/database_helper.dart';

/// 2 haftalık ortak diyet planı
class SharedDietWeek {
  final int weekNumber; // 1 veya 2
  final Map<int, DailyMealPlan> dailyPlans; // dayIndex -> plan (0=Monday, 6=Sunday)

  SharedDietWeek({
    required this.weekNumber,
    required this.dailyPlans,
  });
}

class DailyMealPlan {
  final String breakfast;
  final String lunch;
  final String dinner;
  final String snack;
  final Map<String, double> nutrition; // calories, protein, carbs, fat, iron, etc.
  final List<String> focusAreas; // ['iron_boost', 'anti_inflammatory', etc.]

  DailyMealPlan({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.nutrition,
    required this.focusAreas,
  });
}

/// AI destekli ortak diyet oluşturma servisi
class AISharedDietService {
  static final AISharedDietService _instance = AISharedDietService._internal();
  factory AISharedDietService() => _instance;
  AISharedDietService._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// İki kişinin hemogram değerlerine göre 2 haftalık ortak diyet planı oluştur
  Future<List<SharedDietWeek>> generateSharedDietPlan({
    required int userId1,
    required int userId2,
    required String planName,
  }) async {
    try {
      // Her iki kullanıcının son hemogram testlerini al
      final test1 = await _db.getLatestHemogramTest(userId1);
      final test2 = await _db.getLatestHemogramTest(userId2);

      // Kullanıcı bilgilerini al (yaş, cinsiyet) - şimdilik sadece hemogram değerleri kullanılıyor

      // Hemogram değerlerini parse et
      final values1 = _extractHemogramValues(test1);
      final values2 = _extractHemogramValues(test2);

      // Ortak kritik değerleri belirle
      final criticalAreas = _identifyCriticalAreas(values1, values2);

      // 2 haftalık plan oluştur
      final week1 = _generateWeekPlan(weekNumber: 1, criticalAreas: criticalAreas, values1: values1, values2: values2);
      final week2 = _generateWeekPlan(weekNumber: 2, criticalAreas: criticalAreas, values1: values1, values2: values2);

      return [week1, week2];
    } catch (e, stackTrace) {
      debugPrint('AI Shared Diet Generation Error: $e\n$stackTrace');
      rethrow;
    }
  }

  Map<String, double> _extractHemogramValues(Map<String, dynamic>? test) {
    if (test == null) return {};
    return {
      'hemoglobin': (test['hemoglobin'] as num?)?.toDouble() ?? 0,
      'iron': (test['iron'] as num?)?.toDouble() ?? 0,
      'glucose': (test['glucose'] as num?)?.toDouble() ?? 0,
      'crp': (test['crp'] as num?)?.toDouble() ?? 0,
      'vitamin_d3': (test['vitamin_d3'] as num?)?.toDouble() ?? 0,
      'vitamin_b12': (test['vitamin_b12'] as num?)?.toDouble() ?? 0,
      'calcium': (test['calcium'] as num?)?.toDouble() ?? 0,
    };
  }

  List<String> _identifyCriticalAreas(Map<String, double> values1, Map<String, double> values2) {
    final criticalAreas = <String>[];
    
    // Reference ranges
    const ref = {
      'hemoglobin': {'min': 12.0, 'max': 17.0},
      'iron': {'min': 60.0, 'max': 170.0},
      'glucose': {'min': 70.0, 'max': 100.0},
      'crp': {'min': 0.0, 'max': 5.0},
      'vitamin_d3': {'min': 20.0, 'max': 50.0},
      'vitamin_b12': {'min': 200.0, 'max': 900.0},
      'calcium': {'min': 8.6, 'max': 10.2},
    };

    // Her iki kişide de düşük olan değerleri bul
    for (final key in ref.keys) {
      final v1 = values1[key] ?? 0;
      final v2 = values2[key] ?? 0;
      final min = ref[key]!['min']!;
      final max = ref[key]!['max']!;

      if (v1 < min || v2 < min) {
        switch (key) {
          case 'hemoglobin':
          case 'iron':
            if (!criticalAreas.contains('iron_boost')) criticalAreas.add('iron_boost');
            break;
          case 'vitamin_d3':
            if (!criticalAreas.contains('vitamin_d_boost')) criticalAreas.add('vitamin_d_boost');
            break;
          case 'vitamin_b12':
            if (!criticalAreas.contains('b12_boost')) criticalAreas.add('b12_boost');
            break;
          case 'calcium':
            if (!criticalAreas.contains('calcium_boost')) criticalAreas.add('calcium_boost');
            break;
        }
      }

      if (v1 > max || v2 > max) {
        switch (key) {
          case 'glucose':
            if (!criticalAreas.contains('blood_sugar_control')) criticalAreas.add('blood_sugar_control');
            break;
          case 'crp':
            if (!criticalAreas.contains('anti_inflammatory')) criticalAreas.add('anti_inflammatory');
            break;
        }
      }
    }

    // Eğer hiçbir kritik alan yoksa, genel sağlıklı diyet
    if (criticalAreas.isEmpty) {
      criticalAreas.add('balanced_nutrition');
    }

    return criticalAreas;
  }

  SharedDietWeek _generateWeekPlan({
    required int weekNumber,
    required List<String> criticalAreas,
    required Map<String, double> values1,
    required Map<String, double> values2,
  }) {
    final dailyPlans = <int, DailyMealPlan>{};

    // 7 gün için plan oluştur (Pazartesi=0, Pazar=6)
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      dailyPlans[dayIndex] = _generateDailyPlan(
        dayIndex: dayIndex,
        weekNumber: weekNumber,
        criticalAreas: criticalAreas,
      );
    }

    return SharedDietWeek(
      weekNumber: weekNumber,
      dailyPlans: dailyPlans,
    );
  }

  DailyMealPlan _generateDailyPlan({
    required int dayIndex,
    required int weekNumber,
    required List<String> criticalAreas,
  }) {
    // AI destekli yemek önerileri
    final breakfast = _generateBreakfast(dayIndex: dayIndex, criticalAreas: criticalAreas);
    final lunch = _generateLunch(dayIndex: dayIndex, criticalAreas: criticalAreas);
    final dinner = _generateDinner(dayIndex: dayIndex, criticalAreas: criticalAreas);
    final snack = _generateSnack(dayIndex: dayIndex, criticalAreas: criticalAreas);

    // Beslenme bilgileri hesapla
    final nutrition = _calculateNutrition(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      snack: snack,
      criticalAreas: criticalAreas,
    );

    return DailyMealPlan(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      snack: snack,
      nutrition: nutrition,
      focusAreas: criticalAreas,
    );
  }

  String _generateBreakfast({required int dayIndex, required List<String> criticalAreas}) {
    final loc = LocalizationService();
    List<String> list;
    if (criticalAreas.contains('iron_boost')) {
      list = loc.getString('diet_breakfast_iron_list').split('\n');
    } else if (criticalAreas.contains('blood_sugar_control')) {
      list = loc.getString('diet_breakfast_sugar_list').split('\n');
    } else if (criticalAreas.contains('anti_inflammatory')) {
      list = loc.getString('diet_breakfast_antiinf_list').split('\n');
    } else {
      list = loc.getString('diet_breakfast_balanced_list').split('\n');
    }
    if (list.isEmpty) {
      return loc.getString('balanced_breakfast_label');
    }
    return list[dayIndex % list.length];
  }

  String _generateLunch({required int dayIndex, required List<String> criticalAreas}) {
    final loc = LocalizationService();
    List<String> list;
    if (criticalAreas.contains('iron_boost')) {
      list = loc.getString('diet_lunch_iron_list').split('\n');
    } else if (criticalAreas.contains('blood_sugar_control')) {
      list = loc.getString('diet_lunch_sugar_list').split('\n');
    } else if (criticalAreas.contains('anti_inflammatory')) {
      list = loc.getString('diet_lunch_antiinf_list').split('\n');
    } else {
      list = loc.getString('diet_lunch_balanced_list').split('\n');
    }
    return list.isEmpty ? '' : list[dayIndex % list.length];
  }

  String _generateDinner({required int dayIndex, required List<String> criticalAreas}) {
    final loc = LocalizationService();
    List<String> list;
    if (criticalAreas.contains('iron_boost')) {
      list = loc.getString('diet_dinner_iron_list').split('\n');
    } else if (criticalAreas.contains('blood_sugar_control')) {
      list = loc.getString('diet_dinner_sugar_list').split('\n');
    } else if (criticalAreas.contains('anti_inflammatory')) {
      list = loc.getString('diet_dinner_antiinf_list').split('\n');
    } else {
      list = loc.getString('diet_dinner_balanced_list').split('\n');
    }
    return list.isEmpty ? '' : list[dayIndex % list.length];
  }

  String _generateSnack({required int dayIndex, required List<String> criticalAreas}) {
    final loc = LocalizationService();
    List<String> list;
    if (criticalAreas.contains('iron_boost')) {
      list = loc.getString('diet_snack_iron_list').split('\n');
    } else if (criticalAreas.contains('blood_sugar_control')) {
      list = loc.getString('diet_snack_sugar_list').split('\n');
    } else if (criticalAreas.contains('anti_inflammatory')) {
      list = loc.getString('diet_snack_antiinf_list').split('\n');
    } else {
      list = loc.getString('diet_snack_balanced_list').split('\n');
    }
    return list.isEmpty ? '' : list[dayIndex % list.length];
  }

  Map<String, double> _calculateNutrition({
    required String breakfast,
    required String lunch,
    required String dinner,
    required String snack,
    required List<String> criticalAreas,
  }) {
    // Basit beslenme hesaplaması (gerçek uygulamada daha detaylı olabilir)
    double baseCalories = 1800.0;
    double baseProtein = 80.0;
    double baseCarbs = 200.0;
    double baseFat = 60.0;
    double iron = 15.0;
    double vitaminD = 5.0;
    double vitaminB12 = 3.0;

    if (criticalAreas.contains('iron_boost')) {
      baseCalories += 100;
      baseProtein += 20;
      iron += 10;
    }
    if (criticalAreas.contains('blood_sugar_control')) {
      baseCarbs -= 30;
      baseProtein += 10;
    }
    if (criticalAreas.contains('anti_inflammatory')) {
      baseFat += 10;
      baseCalories += 50;
    }

    return {
      'calories': baseCalories,
      'protein': baseProtein,
      'carbs': baseCarbs,
      'fat': baseFat,
      'iron': iron,
      'vitamin_d': vitaminD,
      'vitamin_b12': vitaminB12,
    };
  }
}

