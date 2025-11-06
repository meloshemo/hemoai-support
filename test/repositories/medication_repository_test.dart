import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/repositories/medication_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MedicationRepository', () {
    late MedicationRepository medicationRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      medicationRepository = MedicationRepository();
    });

    group('Medication CRUD', () {
      test('should add medication', () async {
        final medicationId = await medicationRepository.addMedication(
          userId: 1,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'daily',
          time: '08:00',
        );
        
        expect(medicationId, isA<int>());
        expect(medicationId, greaterThan(0));
      });

      test('should get medications for user', () async {
        await medicationRepository.addMedication(
          userId: 1,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'daily',
          time: '08:00',
        );
        
        final medications = await medicationRepository.getMedications(1);
        expect(medications, isA<List<Map<String, dynamic>>>());
        expect(medications.length, greaterThanOrEqualTo(1));
      });

      test('should return empty list for user with no medications', () async {
        final medications = await medicationRepository.getMedications(999);
        expect(medications, isA<List<Map<String, dynamic>>>());
        expect(medications.length, equals(0));
      });
    });

    group('Medication Tracking', () {
      test('should update medication taken status', () async {
        final medicationId = await medicationRepository.addMedication(
          userId: 1,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'daily',
          time: '08:00',
        );
        
        await medicationRepository.updateMedicationTaken(medicationId, 1, true);
        
        final wasTaken = await medicationRepository.wasMedicationTakenToday(medicationId);
        expect(wasTaken, true);
      });

      test('should check if medication was taken today', () async {
        final medicationId = await medicationRepository.addMedication(
          userId: 1,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'daily',
          time: '08:00',
        );
        
        // Initially not taken
        final wasTaken1 = await medicationRepository.wasMedicationTakenToday(medicationId);
        expect(wasTaken1, false);
        
        // Mark as taken
        await medicationRepository.updateMedicationTaken(medicationId, 1, true);
        
        // Should be taken
        final wasTaken2 = await medicationRepository.wasMedicationTakenToday(medicationId);
        expect(wasTaken2, true);
      });

      test('should handle multiple medications', () async {
        final med1 = await medicationRepository.addMedication(
          userId: 1,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'daily',
          time: '08:00',
        );
        
        final med2 = await medicationRepository.addMedication(
          userId: 1,
          name: 'Vitamin D',
          dosage: '1000IU',
          frequency: 'daily',
          time: '12:00',
        );
        
        await medicationRepository.updateMedicationTaken(med1, 1, true);
        await medicationRepository.updateMedicationTaken(med2, 1, false);
        
        expect(await medicationRepository.wasMedicationTakenToday(med1), true);
        expect(await medicationRepository.wasMedicationTakenToday(med2), false);
      });
    });
  });
}

