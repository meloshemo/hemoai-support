import 'package:flutter/foundation.dart';
import 'preferences_service.dart';
import 'database_helper.dart';
import 'localization_service.dart';

class ActiveProfileService extends ChangeNotifier {
  int? _activeUserId;
  String? _activeUserName;

  int? get activeUserId => _activeUserId;
  String get displayName => _activeUserName ?? LocalizationService().getString('you');

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _activeUserId = prefs.getCurrentUserId();

    if (_activeUserId != null) {
      final db = DatabaseHelper.instance;
      final user = await db.getUserById(_activeUserId!);
      _activeUserName = user?['name']?.toString();
    }
    notifyListeners();
  }

  Future<void> setActiveUser(int userId) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setCurrentUserId(userId);
    _activeUserId = userId;
    final db = DatabaseHelper.instance;
    final user = await db.getUserById(userId);
    _activeUserName = user?['name']?.toString();
    notifyListeners();
  }
}
