import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

/// WaterRepository centralizes water intake tracking operations.
class WaterRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> getTodayWaterIntake(int userId) async {
    try {
      return await _db.getTodayWaterIntake(userId);
    } catch (e) {
      debugPrint('WaterRepository.getTodayWaterIntake error: $e');
      return 0;
    }
  }

  Future<int> logWaterIntake({required int userId, required int amount}) async {
    try {
      return await _db.logWaterIntake(userId, amount);
    } catch (e) {
      debugPrint('WaterRepository.logWaterIntake error: $e');
      return 0;
    }
  }

  Future<List<int>> getLast7DaysWaterIntake(int userId) async {
    try {
      return await _db.getLast7DaysWaterIntake(userId);
    } catch (e) {
      debugPrint('WaterRepository.getLast7DaysWaterIntake error: $e');
      return List<int>.filled(7, 0);
    }
  }
}
