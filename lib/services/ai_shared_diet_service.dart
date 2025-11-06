import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';

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
    final meals = <String>[];
    
    if (criticalAreas.contains('iron_boost')) {
      final ironMeals = [
        'Yulaf ezmesi + pekmez + ceviz + kuru üzüm',
        'Haşlanmış yumurta + tam buğday ekmeği + portakal',
        'Ispanaklı omlet + tam tahıl ekmeği + domates',
        'Mercimek çorbası + tam buğday ekmeği',
        'Kırmızı et + yumurta + tam buğday ekmeği',
        'Yulaf + badem + kuru kayısı',
        'Tam tahıl gevrek + süt + çilek',
      ];
      meals.add(ironMeals[dayIndex % ironMeals.length]);
    } else if (criticalAreas.contains('blood_sugar_control')) {
      final sugarMeals = [
        'Yumurta + avokado + tam buğday ekmeği',
        'Yulaf + badem + yaban mersini',
        'Peynir + tam tahıl ekmeği + domates',
        'Yumurta + sebze + tam buğday',
        'Yoğurt + kuru yemiş + meyve',
        'Tam tahıl gevrek + süt',
        'Sebzeli omlet + tam buğday',
      ];
      meals.add(sugarMeals[dayIndex % sugarMeals.length]);
    } else if (criticalAreas.contains('anti_inflammatory')) {
      final antiInfMeals = [
        'Yulaf + zerdeçal + zencefil + badem',
        'Yumurta + avokado + yeşil sebzeler',
        'Yoğurt + yaban mersini + chia tohumu',
        'Tam tahıl ekmeği + zeytin + domates',
        'Sebzeli omlet + tam buğday',
        'Yulaf + ceviz + meyve',
        'Yoğurt + kuru yemiş + meyve',
      ];
      meals.add(antiInfMeals[dayIndex % antiInfMeals.length]);
    } else {
      final balancedMeals = [
        'Yumurta + tam buğday ekmeği + peynir + domates',
        'Yulaf + süt + meyve + kuruyemiş',
        'Yoğurt + granola + meyve',
        'Sebzeli omlet + tam tahıl ekmeği',
        'Tam tahıl gevrek + süt + meyve',
        'Peynir + zeytin + tam buğday ekmeği',
        'Yumurta + avokado + tam buğday',
      ];
      meals.add(balancedMeals[dayIndex % balancedMeals.length]);
    }

    return meals.isNotEmpty ? meals.first : 'Dengeli kahvaltı';
  }

  String _generateLunch({required int dayIndex, required List<String> criticalAreas}) {
    if (criticalAreas.contains('iron_boost')) {
      final ironMeals = [
        'Izgara kırmızı et + yeşil salata + kinoa',
        'Karaciğer + bulgur pilavı + salata',
        'Balık + ıspanak + tam buğday',
        'Kırmızı et + mercimek + salata',
        'Tavuk + yeşil yapraklı sebze + bulgur',
        'Balık + brokoli + kinoa',
        'Kırmızı et + fasulye + salata',
      ];
      return ironMeals[dayIndex % ironMeals.length];
    } else if (criticalAreas.contains('blood_sugar_control')) {
      final sugarMeals = [
        'Izgara tavuk + yeşil salata + kinoa',
        'Balık + sebze + tam buğday',
        'Tavuk + sebze + bulgur',
        'Izgara et + salata',
        'Balık + salata + tam buğday',
        'Tavuk + sebze + kinoa',
        'Izgara et + yeşil sebze',
      ];
      return sugarMeals[dayIndex % sugarMeals.length];
    } else if (criticalAreas.contains('anti_inflammatory')) {
      final antiInfMeals = [
        'Somon + yeşil salata + kinoa',
        'Balık + zeytinyağlı sebze + tam buğday',
        'Tavuk + antioksidan sebzeler + bulgur',
        'Balık + salata + avokado',
        'Somon + brokoli + kinoa',
        'Balık + yeşil yapraklı + tam buğday',
        'Tavuk + sebze + kinoa',
      ];
      return antiInfMeals[dayIndex % antiInfMeals.length];
    } else {
      final balancedMeals = [
        'Izgara tavuk + salata + bulgur',
        'Balık + sebze + tam buğday',
        'Tavuk + sebze + kinoa',
        'Izgara et + salata + bulgur',
        'Balık + yeşil sebze + tam buğday',
        'Tavuk + salata + kinoa',
        'Izgara et + sebze + bulgur',
      ];
      return balancedMeals[dayIndex % balancedMeals.length];
    }
  }

  String _generateDinner({required int dayIndex, required List<String> criticalAreas}) {
    if (criticalAreas.contains('iron_boost')) {
      final ironMeals = [
        'Kırmızı et + mercimek çorbası + salata',
        'Balık + ıspanak + tam buğday',
        'Tavuk + yeşil yapraklı + bulgur',
        'Kırmızı et + fasulye + salata',
        'Balık + brokoli + kinoa',
        'Tavuk + mercimek + salata',
        'Kırmızı et + sebze + tam buğday',
      ];
      return ironMeals[dayIndex % ironMeals.length];
    } else if (criticalAreas.contains('blood_sugar_control')) {
      final sugarMeals = [
        'Izgara tavuk + sebze + salata',
        'Balık + yeşil sebze',
        'Tavuk + salata',
        'Izgara et + sebze',
        'Balık + salata',
        'Tavuk + sebze',
        'Izgara et + salata',
      ];
      return sugarMeals[dayIndex % sugarMeals.length];
    } else if (criticalAreas.contains('anti_inflammatory')) {
      final antiInfMeals = [
        'Somon + yeşil salata',
        'Balık + zeytinyağlı sebze',
        'Tavuk + antioksidan sebzeler',
        'Balık + salata',
        'Somon + brokoli',
        'Balık + yeşil yapraklı',
        'Tavuk + sebze',
      ];
      return antiInfMeals[dayIndex % antiInfMeals.length];
    } else {
      final balancedMeals = [
        'Izgara tavuk + salata',
        'Balık + sebze',
        'Tavuk + salata',
        'Izgara et + sebze',
        'Balık + salata',
        'Tavuk + sebze',
        'Izgara et + salata',
      ];
      return balancedMeals[dayIndex % balancedMeals.length];
    }
  }

  String _generateSnack({required int dayIndex, required List<String> criticalAreas}) {
    if (criticalAreas.contains('iron_boost')) {
      final snacks = ['Kuru kayısı + ceviz', 'Pekmez + tahin', 'Kuru üzüm + badem', 'Hurma + ceviz', 'Kuru incir + fındık', 'Pekmez + tam buğday', 'Kuru meyve + kuruyemiş'];
      return snacks[dayIndex % snacks.length];
    } else if (criticalAreas.contains('blood_sugar_control')) {
      final snacks = ['Badem + meyve', 'Yoğurt + meyve', 'Kuru yemiş', 'Sebze çubukları', 'Badem + elma', 'Yoğurt', 'Kuru yemiş karışımı'];
      return snacks[dayIndex % snacks.length];
    } else if (criticalAreas.contains('anti_inflammatory')) {
      final snacks = ['Ceviz + yaban mersini', 'Badem + meyve', 'Chia pudingi', 'Kuru yemiş', 'Meyve + kuruyemiş', 'Yoğurt + meyve', 'Kuru yemiş karışımı'];
      return snacks[dayIndex % snacks.length];
    } else {
      final snacks = ['Meyve + kuruyemiş', 'Yoğurt + meyve', 'Kuru yemiş', 'Sebze çubukları', 'Badem + meyve', 'Yoğurt', 'Kuru yemiş karışımı'];
      return snacks[dayIndex % snacks.length];
    }
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

