import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

// Tables
@DriftDatabase(tables: [
  Users,
  BloodTestResults,
  DietPrograms,
  Reminders,
  FamilyMembers,
  HealthMetrics,
  Notifications,
  AuditLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add new columns for v2
        await m.addColumn(bloodTestResults, bloodTestResults.importSource);
        await m.addColumn(bloodTestResults, bloodTestResults.riskLevel);
      }
      if (from < 3) {
        // Add health metrics table for v3
        await m.createTable(healthMetrics);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // Web implementation uses SharedPreferences via WebDatabaseHelper
      // Note: This AppDatabase is only used by HealthSync service
      // The main app uses DatabaseHelper which properly handles web
      throw UnsupportedError('AppDatabase not available on web. Use DatabaseHelper instead.');
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'hemoai_v2.db'));
      return NativeDatabase.createInBackground(file);
    }
  });
}

// User Table
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().withLength(min: 1, max: 255).unique()();
  TextColumn get phone => text().withLength(min: 1, max: 20)();
  TextColumn get passwordHash => text().withLength(min: 1, max: 255)();
  IntColumn get age => integer()();
  TextColumn get gender => text().withLength(min: 1, max: 10)();
  RealColumn get height => real()();
  RealColumn get weight => real()();
  TextColumn get bloodType => text().withLength(min: 1, max: 5)();
  TextColumn get medicalHistory => text().nullable()();
  TextColumn get allergies => text().nullable()();
  TextColumn get medications => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// Blood Test Results Table
class BloodTestResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get testDate => text()();
  TextColumn get laboratoryName => text().nullable()();
  TextColumn get doctorName => text().nullable()();
  TextColumn get testType => text().nullable()();
  TextColumn get importSource => text().nullable()(); // 'manual', 'ocr', 'import'
  
  // Hemogram
  RealColumn get hemoglobin => real().nullable()();
  RealColumn get hematocrit => real().nullable()();
  RealColumn get redBloodCells => real().nullable()();
  RealColumn get whiteBloodCells => real().nullable()();
  RealColumn get platelets => real().nullable()();
  RealColumn get mcv => real().nullable()();
  RealColumn get mch => real().nullable()();
  RealColumn get mchc => real().nullable()();
  RealColumn get rdw => real().nullable()();
  RealColumn get mpv => real().nullable()();
  
  // WBC Differential
  RealColumn get neutrophils => real().nullable()();
  RealColumn get lymphocytes => real().nullable()();
  RealColumn get monocytes => real().nullable()();
  RealColumn get eosinophils => real().nullable()();
  RealColumn get basophils => real().nullable()();
  
  // Iron Studies
  RealColumn get iron => real().nullable()();
  RealColumn get ferritin => real().nullable()();
  RealColumn get transferrin => real().nullable()();
  RealColumn get tibc => real().nullable()();
  RealColumn get transferrinSaturation => real().nullable()();
  
  // Liver Function
  RealColumn get alt => real().nullable()();
  RealColumn get ast => real().nullable()();
  RealColumn get alp => real().nullable()();
  RealColumn get ggt => real().nullable()();
  RealColumn get bilirubin => real().nullable()();
  RealColumn get directBilirubin => real().nullable()();
  RealColumn get albumin => real().nullable()();
  RealColumn get totalProtein => real().nullable()();
  
  // Kidney Function
  RealColumn get creatinine => real().nullable()();
  RealColumn get urea => real().nullable()();
  RealColumn get uricAcid => real().nullable()();
  RealColumn get gfr => real().nullable()();
  
  // Lipid Profile
  RealColumn get totalCholesterol => real().nullable()();
  RealColumn get ldlCholesterol => real().nullable()();
  RealColumn get hdlCholesterol => real().nullable()();
  RealColumn get triglycerides => real().nullable()();
  RealColumn get nonHdlCholesterol => real().nullable()();
  
  // Diabetes
  RealColumn get glucose => real().nullable()();
  RealColumn get hba1c => real().nullable()();
  RealColumn get fructosamine => real().nullable()();
  
  // Thyroid
  RealColumn get tsh => real().nullable()();
  RealColumn get t3 => real().nullable()();
  RealColumn get t4 => real().nullable()();
  RealColumn get freeT3 => real().nullable()();
  RealColumn get freeT4 => real().nullable()();
  
  // Electrolytes
  RealColumn get sodium => real().nullable()();
  RealColumn get potassium => real().nullable()();
  RealColumn get chloride => real().nullable()();
  RealColumn get calcium => real().nullable()();
  RealColumn get magnesium => real().nullable()();
  RealColumn get phosphorus => real().nullable()();
  
  // Vitamins
  RealColumn get vitaminB12 => real().nullable()();
  RealColumn get vitaminD => real().nullable()();
  RealColumn get folate => real().nullable()();
  RealColumn get vitaminA => real().nullable()();
  RealColumn get vitaminE => real().nullable()();
  RealColumn get vitaminC => real().nullable()();
  
  // Additional markers
  RealColumn get crp => real().nullable()();
  RealColumn get esr => real().nullable()();
  RealColumn get insulin => real().nullable()();
  RealColumn get cortisol => real().nullable()();
  
  TextColumn get notes => text().nullable()();
  TextColumn get riskLevel => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Diet Programs Table
class DietPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get titleKey => text().withLength(min: 1, max: 100)();
  TextColumn get descriptionKey => text()();
  TextColumn get includeKey => text()();
  TextColumn get limitKey => text()();
  TextColumn get riskTag => text().withLength(min: 1, max: 50)();
  TextColumn get macrosKey => text().nullable()();
  TextColumn get sampleMenuKey => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Reminders Table
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get scheduledTime => dateTime()();
  TextColumn get repeatPattern => text().withLength(min: 1, max: 50)(); // 'daily', 'weekly', 'monthly', 'none'
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get reminderType => text().withLength(min: 1, max: 50)(); // 'medication', 'test', 'appointment'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Family Members Table
class FamilyMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentUserId => integer().references(Users, #id)();
  IntColumn get memberUserId => integer().references(Users, #id)();
  TextColumn get relationship => text().withLength(min: 1, max: 50)();
  TextColumn get permissions => text()(); // JSON string of permissions
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Health Metrics Table (for tracking trends)
class HealthMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get metricType => text().withLength(min: 1, max: 50)(); // 'weight', 'blood_pressure', 'heart_rate'
  RealColumn get value => real()();
  TextColumn get unit => text().withLength(min: 1, max: 20)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Notifications Table
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text()();
  TextColumn get type => text().withLength(min: 1, max: 50)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get scheduledFor => dateTime()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Audit Logs Table
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get action => text().withLength(min: 1, max: 100)();
  TextColumn get details => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  TextColumn get userAgent => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
