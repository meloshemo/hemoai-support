import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';

/// Lightweight, optional AES encryption helper for Firestore payloads.
///
/// Usage:
/// - Toggle via PreferencesService key 'firestore_encrypt_enabled' (bool)
/// - Secret key via PreferencesService key 'firestore_encrypt_key' (base64-encoded 32 bytes)
/// - Data is encoded as: 'enc:aes256cbc:[base64-iv]:[base64-ciphertext]'
class FirestoreEncryption {
  static const String _enabledKey = 'firestore_encrypt_enabled';
  static const String _secretKey = 'firestore_encrypt_key';

  static Future<bool> isEnabled() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getCustomSetting<bool>(_enabledKey) ?? false;
  }

  static Future<enc.Key?> _loadKey() async {
    final prefs = await PreferencesService.getInstance();
    final b64 = prefs.getCustomSetting<String>(_secretKey);
    if (b64 == null || b64.isEmpty) return null;
    try {
      final bytes = base64Decode(b64);
      if (bytes.length != 32) return null; // AES-256
      return enc.Key(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  static String _format(enc.IV iv, Uint8List data) {
    final ivB64 = base64Encode(iv.bytes);
    final ctB64 = base64Encode(data);
    return 'enc:aes256cbc:$ivB64:$ctB64';
  }

  static ({enc.IV iv, Uint8List data})? _parse(String s) {
    if (!s.startsWith('enc:aes256cbc:')) return null;
    final parts = s.split(':');
    if (parts.length != 4) return null;
    try {
      final iv = enc.IV(Uint8List.fromList(base64Decode(parts[2])));
      final data = Uint8List.fromList(base64Decode(parts[3]));
      return (iv: iv, data: data);
    } catch (_) {
      return null;
    }
  }

  static Future<String> maybeEncryptString(String value) async {
    final enabled = await isEnabled();
    if (!enabled) return value;
    final key = await _loadKey();
    if (key == null) return value;
    try {
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(value, iv: iv);
      return _format(iv, encrypted.bytes);
    } catch (e) {
      debugPrint('[FirestoreEncryption] encrypt error: $e');
      return value;
    }
  }

  static Future<String> maybeDecryptString(String value) async {
    final parsed = _parse(value);
    if (parsed == null) return value;
    final key = await _loadKey();
    if (key == null) return value; // cannot decrypt
    try {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final ct = enc.Encrypted(parsed.data);
      final plain = encrypter.decrypt(ct, iv: parsed.iv);
      return plain;
    } catch (e) {
      debugPrint('[FirestoreEncryption] decrypt error: $e');
      return value;
    }
  }

  /// Encrypt selected fields of a map, returning a new map.
  static Future<Map<String, dynamic>> maybeEncryptMap(
    Map<String, dynamic> src, {
    required List<String> fields,
  }) async {
    final out = Map<String, dynamic>.from(src);
    for (final f in fields) {
      final v = out[f];
      if (v is String && v.isNotEmpty) {
        out[f] = await maybeEncryptString(v);
      }
    }
    return out;
  }

  /// Decrypt selected fields of a map in-place if they appear encrypted.
  static Future<Map<String, dynamic>> maybeDecryptMap(
    Map<String, dynamic> src, {
    required List<String> fields,
  }) async {
    final out = Map<String, dynamic>.from(src);
    for (final f in fields) {
      final v = out[f];
      if (v is String && v.startsWith('enc:aes256cbc:')) {
        out[f] = await maybeDecryptString(v);
      }
    }
    return out;
  }
}
