import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

/// MedicationRepository centralizes medication CRUD across platforms.
class MedicationRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getMedications(int userId) async {
    try {
      return await _db.getMedications(userId);
    } catch (e) {
      debugPrint('MedicationRepository.getMedications error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<int> addMedication({
    required int userId,
    required String name,
    required String dosage,
    required String frequency,
    required String time,
  }) async {
    try {
      return await _db.addMedication(userId, name, dosage, frequency, time);
    } catch (e) {
      debugPrint('MedicationRepository.addMedication error: $e');
      return 0;
    }
  }

  Future<void> updateMedicationTaken(int medicationId, int userId, bool taken) async {
    try {
      await _db.updateMedicationTaken(medicationId, userId, taken);
    } catch (e) {
      debugPrint('MedicationRepository.updateMedicationTaken error: $e');
      rethrow;
    }
  }

  Future<bool> wasMedicationTakenToday(int medicationId) async {
    try {
      return await _db.wasMedicationTakenToday(medicationId);
    } catch (e) {
      debugPrint('MedicationRepository.wasMedicationTakenToday error: $e');
      return false;
    }
  }
}
