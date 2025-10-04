import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PreferencesService {
  static PreferencesService? _instance;
  static SharedPreferences? _preferences;

  static Future<PreferencesService> getInstance() async {
    _instance ??= PreferencesService();
    _preferences ??= await SharedPreferences.getInstance();
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
    await _preferences!.setString('user_email', email);
    await _preferences!.setString('user_phone', phone);
    await _preferences!.setInt('user_age', age);
    await _preferences!.setString('user_gender', gender);
    await _preferences!.setDouble('user_height', height);
    await _preferences!.setDouble('user_weight', weight);
    await _preferences!.setBool('user_logged_in', true);
  }

  Map<String, dynamic>? getUserInfo() {
    if (!(_preferences?.getBool('user_logged_in') ?? false)) return null;
    
    return {
      'name': _preferences?.getString('user_name'),
      'email': _preferences?.getString('user_email'),
      'phone': _preferences?.getString('user_phone'),
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
  Future<void> setUserInfo(String name, String email, String phone) async {
    if (_preferences == null) {
      await getInstance();
    }
    await _preferences!.setString('user_name', name);
    await _preferences!.setString('user_email', email);
    await _preferences!.setString('user_phone', phone);
  }

  Future<void> setPersonalInfo(int age, String gender, double height, double weight) async {
    if (_preferences == null) {
      await getInstance();
    }
    await _preferences!.setInt('user_age', age);
    await _preferences!.setString('user_gender', gender);
    await _preferences!.setDouble('user_height', height);
    await _preferences!.setDouble('user_weight', weight);
  }

  // Hemogram değerleri kaydetme
  Future<void> saveHemogramValues(Map<String, double> values) async {
    String jsonString = jsonEncode(values);
    await _preferences!.setString('last_hemogram', jsonString);
    await _preferences!.setString('last_hemogram_date', DateTime.now().toIso8601String());
  }

  Future<void> setHemogramValues(Map<String, double> values) async {
    await saveHemogramValues(values);
  }

  Map<String, double>? getLastHemogramValues() {
    String? jsonString = _preferences?.getString('last_hemogram');
    if (jsonString == null) return null;
    
    try {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return null;
    }
  }

  String? getLastHemogramDate() {
    return _preferences?.getString('last_hemogram_date');
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
    await _preferences!.setString('water_date', DateTime.now().toIso8601String().substring(0, 10));
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
          'name': 'Iron Supplement',
          'dosage': '1 tablet',
          'frequency': 'Once daily',
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

  bool isFirstLaunch() {
    return _preferences?.getBool('first_launch') ?? true;
  }

  // Kullanıcı çıkışı
  Future<void> logout() async {
    await _preferences!.setBool('user_logged_in', false);
    // Kullanıcı verilerini silmek istemiyoruz, sadece oturumu kapatıyoruz
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
    await _preferences!.setString('last_app_usage', DateTime.now().toIso8601String());
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
}