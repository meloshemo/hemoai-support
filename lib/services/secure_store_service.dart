import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure key-value storage wrapper.
/// Uses flutter_secure_storage when available; falls back to SharedPreferences (with `secure_` prefix)
/// in environments where the plugin isn't available (e.g., some test runners) to avoid crashes.
class SecureStoreService {
  static final SecureStoreService _instance = SecureStoreService._internal();
  factory SecureStoreService() => _instance;
  SecureStoreService._internal();

  // Default options (can be extended per-platform if needed)
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<void> write(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStore write fallback for key=$key due to PlatformException: ${e.message}');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secure_$key', value);
    } catch (e) {
      // Last-resort fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('secure_$key', value);
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _secure.read(key: key);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStore read fallback for key=$key due to PlatformException: ${e.message}');
      }
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('secure_$key');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('secure_$key');
    }
  }

  Future<void> delete(String key) async {
    try {
      await _secure.delete(key: key);
    } on PlatformException catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('secure_$key');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('secure_$key');
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> json) async {
    await write(key, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final s = await read(key);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
