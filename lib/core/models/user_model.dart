import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.g.dart';
part 'user_model.freezed.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String name,
    required String email,
    required String phone,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String bloodType,
    String? medicalHistory,
    String? allergies,
    String? medications,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(true) bool isActive,
    String? profileImageUrl,
    String? emergencyContact,
    String? emergencyPhone,
    String? address,
    String? city,
    String? country,
    String? timezone,
    @Default([]) List<String> preferredLanguages,
    @Default({}) Map<String, dynamic> preferences,
    @Default({}) Map<String, dynamic> healthGoals,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required UserModel user,
    required HealthMetricsSummary healthSummary,
    required List<BloodTestResult> recentTests,
    required List<Reminder> activeReminders,
    required List<DietProgram> activeDiets,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

@freezed
class HealthMetricsSummary with _$HealthMetricsSummary {
  const factory HealthMetricsSummary({
    required double healthScore,
    required String healthGrade,
    required int totalTests,
    required DateTime lastTestDate,
    required List<String> riskFactors,
    required List<String> recommendations,
    required Map<String, double> trendingMetrics,
  }) = _HealthMetricsSummary;

  factory HealthMetricsSummary.fromJson(Map<String, dynamic> json) => _$HealthMetricsSummaryFromJson(json);
}

@freezed
class BloodTestResult with _$BloodTestResult {
  const factory BloodTestResult({
    required int id,
    required int userId,
    required DateTime testDate,
    String? laboratoryName,
    String? doctorName,
    String? testType,
    String? importSource,
    required Map<String, double?> values,
    String? notes,
    String? riskLevel,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _BloodTestResult;

  factory BloodTestResult.fromJson(Map<String, dynamic> json) => _$BloodTestResultFromJson(json);
}

@freezed
class Reminder with _$Reminder {
  const factory Reminder({
    required int id,
    required int userId,
    required String title,
    String? description,
    required DateTime scheduledTime,
    required String repeatPattern,
    @Default(true) bool isActive,
    @Default(false) bool isCompleted,
    required String reminderType,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);
}

@freezed
class DietProgram with _$DietProgram {
  const factory DietProgram({
    required int id,
    required int userId,
    required String titleKey,
    required String descriptionKey,
    required String includeKey,
    required String limitKey,
    required String riskTag,
    String? macrosKey,
    String? sampleMenuKey,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DietProgram;

  factory DietProgram.fromJson(Map<String, dynamic> json) => _$DietProgramFromJson(json);
}

// User Registration Data
@freezed
class UserRegistrationData with _$UserRegistrationData {
  const factory UserRegistrationData({
    required String name,
    required String email,
    required String phone,
    required String password,
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String bloodType,
    String? medicalHistory,
    String? allergies,
    String? medications,
  }) = _UserRegistrationData;

  factory UserRegistrationData.fromJson(Map<String, dynamic> json) => _$UserRegistrationDataFromJson(json);
}

// User Update Data
@freezed
class UserUpdateData with _$UserUpdateData {
  const factory UserUpdateData({
    String? name,
    String? phone,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? bloodType,
    String? medicalHistory,
    String? allergies,
    String? medications,
    String? emergencyContact,
    String? emergencyPhone,
    String? address,
    String? city,
    String? country,
    String? timezone,
    List<String>? preferredLanguages,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? healthGoals,
  }) = _UserUpdateData;

  factory UserUpdateData.fromJson(Map<String, dynamic> json) => _$UserUpdateDataFromJson(json);
}

// User Preferences
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default('en') String language,
    @Default('system') String theme,
    @Default(true) bool notifications,
    @Default(true) bool biometricAuth,
    @Default(true) bool cloudSync,
    @Default(true) bool analytics,
    @Default('metric') String unitSystem,
    @Default('24') String timeFormat,
    @Default('MM/dd/yyyy') String dateFormat,
    @Default(true) bool autoBackup,
    @Default(7) int backupFrequency,
    @Default([]) List<String> reminderTypes,
    @Default({}) Map<String, bool> privacySettings,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);
}

// Health Goals
@freezed
class HealthGoals with _$HealthGoals {
  const factory HealthGoals({
    @Default([]) List<String> primaryGoals,
    @Default([]) List<String> secondaryGoals,
    @Default(0) int targetWeight,
    @Default(0) int targetBMI,
    @Default([]) List<String> fitnessGoals,
    @Default([]) List<String> nutritionGoals,
    @Default({}) Map<String, dynamic> customGoals,
  }) = _HealthGoals;

  factory HealthGoals.fromJson(Map<String, dynamic> json) => _$HealthGoalsFromJson(json);
}
