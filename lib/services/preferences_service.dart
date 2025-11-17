import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'secure_store_service.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../repositories/hemogram_repository.dart';
import 'localization_service.dart';

class PreferencesService {
  static PreferencesService? _instance;
  static SharedPreferences? _preferences;

  static Future<PreferencesService> getInstance() async {
    // Always refresh preferences instance to avoid stale cached values across tests
    _instance ??= PreferencesService();
    _preferences = await SharedPreferences.getInstance();
    return _instance!;
  }

  // Kullanıcı bilgileri
  Future<void> saveUserInfo({
    required String name,
    required String email,
    required String phone,
    required int age,
    required String gender,
    required double height,
    required double weight,
  }) async {
    await _preferences!.setString('user_name', name);
    // Store sensitive fields in secure storage
    await SecureStoreService().write('user_email', email);
    await SecureStoreService().write('user_phone', phone);
    await _preferences!.setInt('user_age', age);
    await _preferences!.setString('user_gender', gender);
    await _preferences!.setDouble('user_height', height);
    await _preferences!.setDouble('user_weight', weight);
    await _preferences!.setBool('user_logged_in', true);
  }

  Map<String, dynamic>? getUserInfo() {
    if (!(_preferences?.getBool('user_logged_in') ?? false)) return null;
    // Email/phone retrieved from secure storage with fallback to prefs if present
    return {
      'name': _preferences?.getString('user_name'),
      // Do NOT read email/phone from SharedPreferences unless legacy values remain.
      // Call getUserInfoAsync() for secure values when possible.
      'email': null,
      'phone': null,
      'emailVerified': _preferences?.getBool('user_email_verified') ?? false,
      'phoneVerified': _preferences?.getBool('user_phone_verified') ?? false,
      'age': _preferences?.getInt('user_age'),
      'gender': _preferences?.getString('user_gender'),
      'height': _preferences?.getDouble('user_height'),
      'weight': _preferences?.getDouble('user_weight'),
    };
  }

  bool isUserLoggedIn() {
    return _preferences?.getBool('user_logged_in') ?? false;
  }

  Future<int?> getUserId() async {
    return _preferences?.getInt('current_user_id');
  }

  Future<void> setUserId(int userId) async {
    await _preferences!.setInt('current_user_id', userId);
  }

  // Kullanıcı oturum yönetimi
  Future<void> setCurrentUserId(int userId) async {
    if (_preferences == null) {
      await getInstance();
    }
    await _preferences!.setInt('current_user_id', userId);
  }

  int? getCurrentUserId() {
    return _preferences?.getInt('current_user_id');
  }

  // Kullanıcı bilgileri
  Future<void> setUserInfo(
    String name,
    String email,
    String phone, {
    bool emailVerified = false,
    bool phoneVerified = false,
  }) async {
    if (_preferences == null) {
      await getInstance();
    }
    await _preferences!.setString('user_name', name);
    await SecureStoreService().write('user_email', email);
    await SecureStoreService().write('user_phone', phone);
    await _preferences!.setBool('user_email_verified', emailVerified);
    await _preferences!.setBool('user_phone_verified', phoneVerified);
    // Treat presence of user info as a signed-in session so app resumes seamlessly
    await _preferences!.setBool('user_logged_in', true);
  }

  Future<void> setVerificationStatus({
    bool? emailVerified,
    bool? phoneVerified,
  }) async {
    if (_preferences == null) {
      await getInstance();
    }
    if (emailVerified != null) {
      await _preferences!.setBool('user_email_verified', emailVerified);
    }
    if (phoneVerified != null) {
      await _preferences!.setBool('user_phone_verified', phoneVerified);
    }
  }

  bool isEmailVerified() {
    return _preferences?.getBool('user_email_verified') ?? false;
  }

  bool isPhoneVerified() {
    return _preferences?.getBool('user_phone_verified') ?? false;
  }

  Future<void> setPersonalInfo(
      int age, String gender, double height, double weight) async {
    if (_preferences == null) {
      await getInstance();
    }
    await _preferences!.setInt('user_age', age);
    await _preferences!.setString('user_gender', gender);
    await _preferences!.setDouble('user_height', height);
    await _preferences!.setDouble('user_weight', weight);
  }

  // Hemogram değerleri kaydetme
  Future<void> saveHemogramValues(Map<String, double> values,
      {DateTime? testDate}) async {
    String jsonString = jsonEncode(values);
    await _preferences!.setString('last_hemogram', jsonString);
    await _preferences!.setString(
        'last_hemogram_date', (testDate ?? DateTime.now()).toIso8601String());
  }

  Future<void> setHemogramValues(Map<String, double> values) async {
    await saveHemogramValues(values);
  }

  Map<String, double>? getLastHemogramValues() {
    String? jsonString = _preferences?.getString('last_hemogram');
    if (jsonString == null) return null;

    try {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return null;
    }
  }

  // Async variant that reads email/phone from secure storage (preferred)
  Future<Map<String, dynamic>?> getUserInfoAsync() async {
    if (!(_preferences?.getBool('user_logged_in') ?? false)) return null;
    final secure = SecureStoreService();
    final email = await secure.read('user_email');
    final phone = await secure.read('user_phone');
    return {
      'name': _preferences?.getString('user_name'),
      'email': email,
      'phone': phone,
      'emailVerified': _preferences?.getBool('user_email_verified') ?? false,
      'phoneVerified': _preferences?.getBool('user_phone_verified') ?? false,
      'age': _preferences?.getInt('user_age'),
      'gender': _preferences?.getString('user_gender'),
      'height': _preferences?.getDouble('user_height'),
      'weight': _preferences?.getDouble('user_weight'),
    };
  }

  // One-time migration: move PII from SharedPreferences -> Secure storage and scrub legacy keys
  Future<void> ensurePiiSecured() async {
    if (_preferences == null) {
      await getInstance();
    }
    final legacyEmail = _preferences?.getString('user_email');
    final legacyPhone = _preferences?.getString('user_phone');
    bool changed = false;
    if (legacyEmail != null && legacyEmail.isNotEmpty) {
      await SecureStoreService().write('user_email', legacyEmail);
      await _preferences!.remove('user_email');
      changed = true;
    }
    if (legacyPhone != null && legacyPhone.isNotEmpty) {
      await SecureStoreService().write('user_phone', legacyPhone);
      await _preferences!.remove('user_phone');
      changed = true;
    }
    if (changed) {
      // Mark that migration happened
      await _preferences!.setBool('pii_migrated_v1', true);
    }
  }

  String? getLastHemogramDate() {
    return _preferences?.getString('last_hemogram_date');
  }

  Future<Map<String, double>?> loadActiveHemogramValues() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    final record = await HemogramRepository().getActiveHemogram(userId);
    if (record == null) return null;
    await saveHemogramValues(record.values, testDate: record.testDate);
    return record.values;
  }

  // Uygulama ayarları
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    String jsonString = jsonEncode(settings);
    await _preferences!.setString('notification_settings', jsonString);
  }

  Map<String, bool> getNotificationSettings() {
    String? jsonString = _preferences?.getString('notification_settings');
    if (jsonString == null) {
      // Varsayılan ayarlar
      return {
        'test_reminders': true,
        'critical_alerts': true,
        'medication_reminders': true,
        'nutrition_tips': false,
        'appointment_reminders': true,
        'water_reminders': true,
        'exercise_reminders': false,
      };
    }

    try {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      return {};
    }
  }

  // Su takibi
  Future<void> saveWaterCount(int count) async {
    await _preferences!.setInt('water_count', count);
    await _preferences!.setString(
        'water_date', DateTime.now().toIso8601String().substring(0, 10));
  }

  int getWaterCount() {
    String today = DateTime.now().toIso8601String().substring(0, 10);
    String? savedDate = _preferences?.getString('water_date');

    if (savedDate != today) {
      // Yeni güne geçilmişse sayacı sıfırla
      saveWaterCount(0);
      return 0;
    }

    return _preferences?.getInt('water_count') ?? 0;
  }

  // İlaç takibi
  Future<void> saveMedications(List<Map<String, dynamic>> medications) async {
    String jsonString = jsonEncode(medications);
    await _preferences!.setString('medications', jsonString);
  }

  List<Map<String, dynamic>> getMedications() {
    String? jsonString = _preferences?.getString('medications');
    if (jsonString == null) {
      // Varsayılan ilaçlar
      return [
        {
          'name': LocalizationService().getString('iron_supplement'),
          'dosage': '1 ${LocalizationService().getString('unit_tablet')}',
          'frequency': LocalizationService().getString('frequency_once_daily'),
          'time': '20:00',
          'taken_today': false,
          'total_days': 30,
          'completed_days': 0,
        },
      ];
    }

    try {
      List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Tema ayarları
  Future<void> saveThemeMode(bool isDarkMode) async {
    await _preferences!.setBool('dark_mode', isDarkMode);
  }

  bool isDarkMode() {
    return _preferences?.getBool('dark_mode') ?? false;
  }

  // İlk açılış kontrolü
  Future<void> setFirstLaunch(bool isFirst) async {
    await _preferences!.setBool('first_launch', isFirst);
  }

  // Danger: Clears local app data (prefs and known secure fields). Does not touch database.
  Future<void> clearAllLocal() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.clear();
    // Clear known secure keys
    final secure = SecureStoreService();
    await secure.delete('user_email');
    await secure.delete('user_phone');
  }

  // ===== Motivation & Challenges =====
  Future<void> setChallengeEnabled(
      {bool? steps, bool? water, bool? sleep}) async {
    if (steps != null) await _preferences!.setBool('challenge_steps', steps);
    if (water != null) await _preferences!.setBool('challenge_water', water);
    if (sleep != null) await _preferences!.setBool('challenge_sleep', sleep);
  }

  bool getChallengeSteps() => _preferences?.getBool('challenge_steps') ?? true;
  bool getChallengeWater() => _preferences?.getBool('challenge_water') ?? true;
  bool getChallengeSleep() => _preferences?.getBool('challenge_sleep') ?? false;

  Future<void> setMotivationTone(String tone) async {
    // 'gentle' | 'active'
    await _preferences!.setString('motivation_tone', tone);
  }

  String getMotivationTone() =>
      _preferences?.getString('motivation_tone') ?? 'gentle';

  Future<void> setDailySummaryTime(int hour, int minute) async {
    await _preferences!.setInt('daily_summary_hour', hour);
    await _preferences!.setInt('daily_summary_minute', minute);
  }

  int getDailySummaryHour() => _preferences?.getInt('daily_summary_hour') ?? 20;
  int getDailySummaryMinute() =>
      _preferences?.getInt('daily_summary_minute') ?? 0;

  bool isFirstLaunch() {
    return _preferences?.getBool('first_launch') ?? true;
  }

  // Kullanıcı çıkışı
  Future<void> logout() async {
    await _preferences!.setBool('user_logged_in', false);
    await _preferences!.setBool('user_email_verified', false);
    await _preferences!.setBool('user_phone_verified', false);
    // Kullanıcı verilerini silmek istemiyoruz, sadece oturumu kapatıyoruz
  }

  // ===== Onboarding & Guest Mode =====
  Future<void> setOnboardingCompleted(bool completed) async {
    await _preferences!.setBool('onboarding_completed', completed);
  }

  bool isOnboardingCompleted() {
    return _preferences?.getBool('onboarding_completed') ?? false;
  }

  Future<void> setGuestMode(bool enabled) async {
    await _preferences!.setBool('guest_mode', enabled);
  }

  bool isGuestMode() {
    return _preferences?.getBool('guest_mode') ?? false;
  }

  Future<void> setDietGoalType(String goalType) async {
    // Store as a normalized lowercase string (e.g., 'weight_loss', 'maintenance', 'muscle_gain')
    await _preferences!.setString('diet_goal_type', goalType.toLowerCase());
  }

  String? getDietGoalType() {
    return _preferences?.getString('diet_goal_type');
  }

  // Çoklu profil yönetimi (IDs listesi)
  Future<List<int>> getKnownUserIds() async {
    final list = _preferences?.getStringList('known_user_ids') ?? <String>[];
    return list.map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0).toList();
  }

  Future<void> addKnownUserId(int userId) async {
    final list = _preferences?.getStringList('known_user_ids') ?? <String>[];
    if (!list.contains(userId.toString())) {
      list.add(userId.toString());
      await _preferences!.setStringList('known_user_ids', list);
    }
  }

  Future<void> removeKnownUserId(int userId) async {
    final list = _preferences?.getStringList('known_user_ids') ?? <String>[];
    list.removeWhere((e) => e == userId.toString());
    await _preferences!.setStringList('known_user_ids', list);
  }

  // Aktif profil değiştirme (oturumu açık kabul ederek)
  Future<void> switchActiveUser(int userId) async {
    await setCurrentUserId(userId);
    await _preferences!.setBool('user_logged_in', true);
    await addKnownUserId(userId);
  }

  // Tüm verileri temizle (uygulama sıfırlama)
  Future<void> clearAllData() async {
    await _preferences!.clear();
  }

  // BMI hesaplama ve kaydetme
  double calculateBMI(double height, double weight) {
    double heightInMeters = height / 100; // cm'den m'ye çevir
    return weight / (heightInMeters * heightInMeters);
  }

  Future<void> saveBMI(double bmi) async {
    await _preferences!.setDouble('current_bmi', bmi);
    await _preferences!.setString('bmi_date', DateTime.now().toIso8601String());
  }

  double? getCurrentBMI() {
    return _preferences?.getDouble('current_bmi');
  }

  // Uygulama istatistikleri
  Future<void> incrementAppUsage() async {
    int currentUsage = _preferences?.getInt('app_usage_count') ?? 0;
    await _preferences!.setInt('app_usage_count', currentUsage + 1);
    await _preferences!
        .setString('last_app_usage', DateTime.now().toIso8601String());
  }

  int getAppUsageCount() {
    return _preferences?.getInt('app_usage_count') ?? 0;
  }

  String? getLastAppUsage() {
    return _preferences?.getString('last_app_usage');
  }

  // Favori bitkiler
  Future<void> saveFavoriteHerbs(List<String> favorites) async {
    await _preferences!.setStringList('favorite_herbs', favorites);
  }

  List<String>? getFavoriteHerbs() {
    return _preferences?.getStringList('favorite_herbs');
  }

  // Alternative medicine search history
  Future<void> saveSearchHistory(List<String> history) async {
    await _preferences!.setStringList('alt_med_search_history', history);
  }

  List<String>? getSearchHistory() {
    return _preferences?.getStringList('alt_med_search_history');
  }

  // User interaction preferences
  Future<void> saveShowOnlyFavorites(bool value) async {
    await _preferences!.setBool('show_only_favorites', value);
  }

  bool getShowOnlyFavorites() {
    return _preferences?.getBool('show_only_favorites') ?? false;
  }

  // Özel ayarlar
  Future<void> setMedicalConsentAccepted(bool accepted) async {
    await _preferences!.setBool('medical_consent_accepted', accepted);
  }

  bool isMedicalConsentAccepted() {
    return _preferences?.getBool('medical_consent_accepted') ?? false;
  }

  Future<void> saveCustomSettings(String key, dynamic value) async {
    if (value is String) {
      await _preferences!.setString('custom_$key', value);
    } else if (value is int) {
      await _preferences!.setInt('custom_$key', value);
    } else if (value is double) {
      await _preferences!.setDouble('custom_$key', value);
    } else if (value is bool) {
      await _preferences!.setBool('custom_$key', value);
    }
  }

  T? getCustomSetting<T>(String key) {
    return _preferences?.get('custom_$key') as T?;
  }

  // ===== Cloud backup preferences =====
  Future<void> setAutoCloudBackupEnabled(bool enabled) async {
    await _preferences!.setBool('auto_cloud_backup_enabled', enabled);
  }

  bool getAutoCloudBackupEnabled() {
    return _preferences?.getBool('auto_cloud_backup_enabled') ?? false;
  }

  // Backward-compatible: alias for new UI toggle expecting 'auto_cloud_backup_enabled'
  // If future key change occurs, map here.

  Future<void> setCloudBackupPassword(String password) async {
    // Store securely
    await SecureStoreService().write('cloud_backup_password', password);
  }

  String? getCloudBackupPassword() {
    // Best-effort sync read; this is async in secure store, so try prefs first (legacy), then secure via blocking read is not possible here.
    // For simplicity, return null here and let callers migrate to async path when needed,
    // or prefer using getCloudBackupPasswordAsync below.
    return null;
  }

  Future<String?> getCloudBackupPasswordAsync() async {
    return SecureStoreService().read('cloud_backup_password');
  }

  Future<void> clearCloudBackupPassword() async {
    await SecureStoreService().delete('cloud_backup_password');
  }

  Future<void> setLastAutoCloudBackup(DateTime ts) async {
    await _preferences!
        .setString('last_auto_cloud_backup', ts.toIso8601String());
  }

  DateTime? getLastAutoCloudBackup() {
    final s = _preferences?.getString('last_auto_cloud_backup');
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  // ===== Water goal preferences =====
  Future<void> setWaterDailyGoal(int glasses) async {
    await _preferences!.setInt('water_daily_goal', glasses);
  }

  int getWaterDailyGoal() {
    return _preferences?.getInt('water_daily_goal') ?? 8;
  }

  // ===== Local lock (PIN) =====
  static const _pinKey = 'pin_hash_v1';
  static const _pinSalt = 'hemoai_salt_v1';

  String _hashPin(String pin) {
    final bytes = utf8.encode('$_pinSalt::$pin');
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> setPIN(String pin) async {
    final hash = _hashPin(pin);
    await SecureStoreService().write(_pinKey, hash);
  }

  Future<bool> hasPIN() async {
    final v = await SecureStoreService().read(_pinKey);
    return (v != null && v.isNotEmpty);
  }

  Future<void> clearPIN() async {
    await SecureStoreService().delete(_pinKey);
  }

  Future<bool> verifyPIN(String pin) async {
    final stored = await SecureStoreService().read(_pinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  // ===== Biometrics (flag + attempt) =====
  Future<void> setBiometricEnabled(bool enabled) async {
    await _preferences!.setBool('biometric_enabled', enabled);
  }

  bool getBiometricEnabled() {
    return _preferences?.getBool('biometric_enabled') ?? false;
  }

  Future<bool> authenticateWithBiometrics(
      {String reason = 'Authenticate'}) async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      return await auth.authenticate(
        localizedReason: reason,
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Biometric auth failed: $e');
      }
      return false;
    }
  }

  // ===== Privacy toggles (data access permissions) =====
  // Generic helpers
  Future<void> setPrivacyFlag(String key, bool value) async {
    await _preferences!.setBool('privacy_$key', value);
  }

  bool getPrivacyFlag(String key, {bool defaultValue = true}) {
    return _preferences?.getBool('privacy_$key') ?? defaultValue;
  }

  // Specific convenience getters
  bool allowInAppReminders() =>
      getPrivacyFlag('allow_in_app_reminders', defaultValue: true);
  bool allowPushNotifications() =>
      getPrivacyFlag('allow_push_notifications', defaultValue: true);
  bool allowMedicationAccess() =>
      getPrivacyFlag('allow_medication_access', defaultValue: true);
  bool allowFamilyFeatures() =>
      getPrivacyFlag('allow_family_features', defaultValue: true);
}
