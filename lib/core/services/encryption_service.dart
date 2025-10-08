import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  static const String _saltStorageKey = 'encryption_salt';
  
  final Logger _logger = Logger();
  SecretKey? _key;
  Salt? _salt;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load existing key and salt
      final keyBytes = prefs.getString(_keyStorageKey);
      final saltBytes = prefs.getString(_saltStorageKey);
      
      if (keyBytes != null && saltBytes != null) {
        _key = SecretKey(base64Decode(keyBytes));
        _salt = Salt(base64Decode(saltBytes));
        _logger.i('Encryption service initialized with existing key');
      } else {
        // Generate new key and salt
        await _generateNewKeyAndSalt();
        _logger.i('Encryption service initialized with new key');
      }
    } catch (e) {
      _logger.e('Failed to initialize encryption service: $e');
      rethrow;
    }
  }

  Future<void> _generateNewKeyAndSalt() async {
    try {
      // Generate a new secret key
      _key = await SecretKey.generate(32);
      
      // Generate a new salt
      _salt = await Salt.generate(16);
      
      // Store key and salt securely
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStorageKey, base64Encode(_key!.extractBytes()));
      await prefs.setString(_saltStorageKey, base64Encode(_salt!.bytes));
      
      _logger.i('Generated new encryption key and salt');
    } catch (e) {
      _logger.e('Failed to generate encryption key: $e');
      rethrow;
    }
  }

  Future<String> encrypt(String plaintext) async {
    try {
      if (_key == null || _salt == null) {
        await initialize();
      }
      
      final algorithm = AesGcm.with256bits();
      final nonce = algorithm.newNonce();
      
      final secretBox = await algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: _key!,
        nonce: nonce,
        aad: utf8.encode('hemoai_encryption'),
      );
      
      // Combine nonce and ciphertext
      final encryptedData = Uint8List.fromList([
        ...nonce.bytes,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);
      
      return base64Encode(encryptedData);
    } catch (e) {
      _logger.e('Encryption failed: $e');
      rethrow;
    }
  }

  Future<String> decrypt(String encryptedText) async {
    try {
      if (_key == null || _salt == null) {
        await initialize();
      }
      
      final encryptedData = base64Decode(encryptedText);
      
      final algorithm = AesGcm.with256bits();
      
      // Extract nonce, ciphertext, and mac
      final nonce = Nonce(encryptedData.sublist(0, 12));
      final cipherText = encryptedData.sublist(12, encryptedData.length - 16);
      final mac = Mac(encryptedData.sublist(encryptedData.length - 16));
      
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
      
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: _key!,
        aad: utf8.encode('hemoai_encryption'),
      );
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      _logger.e('Decryption failed: $e');
      rethrow;
    }
  }

  Future<String> encryptSensitiveData(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      return await encrypt(jsonString);
    } catch (e) {
      _logger.e('Failed to encrypt sensitive data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> decryptSensitiveData(String encryptedData) async {
    try {
      final decryptedJson = await decrypt(encryptedData);
      return jsonDecode(decryptedJson) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to decrypt sensitive data: $e');
      rethrow;
    }
  }

  Future<String> hashPassword(String password, {String? salt}) async {
    try {
      final algorithm = Argon2id(memory: 65536, iterations: 3, parallelism: 4, hashLength: 32);
      final saltToUse = salt != null ? Salt(base64Decode(salt)) : await Salt.generate(16);
      
      final hash = await algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: saltToUse,
      );
      
      return base64Encode(hash.extractBytes());
    } catch (e) {
      _logger.e('Password hashing failed: $e');
      rethrow;
    }
  }

  Future<bool> verifyPassword(String password, String hash, String salt) async {
    try {
      final algorithm = Argon2id(memory: 65536, iterations: 3, parallelism: 4, hashLength: 32);
      final saltBytes = base64Decode(salt);
      final saltObj = Salt(saltBytes);
      
      final computedHash = await algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: saltObj,
      );
      
      final computedHashString = base64Encode(computedHash.extractBytes());
      
      return computedHashString == hash;
    } catch (e) {
      _logger.e('Password verification failed: $e');
      return false;
    }
  }

  Future<String> generateSecureToken({int length = 32}) async {
    try {
      final random = Random();
      final bytes = List<int>.generate(length, (i) => random.nextInt(256));
      return base64Encode(bytes);
    } catch (e) {
      _logger.e('Token generation failed: $e');
      rethrow;
    }
  }

  Future<Uint8List> encryptFile(Uint8List fileData) async {
    try {
      if (_key == null || _salt == null) {
        await initialize();
      }
      
      final algorithm = AesGcm.with256bits();
      final nonce = algorithm.newNonce();
      
      final secretBox = await algorithm.encrypt(
        fileData,
        secretKey: _key!,
        nonce: nonce,
        aad: utf8.encode('hemoai_file_encryption'),
      );
      
      // Combine nonce and ciphertext
      return Uint8List.fromList([
        ...nonce.bytes,
        ...secretBox.cipherText,
        ...secretBox.mac.bytes,
      ]);
    } catch (e) {
      _logger.e('File encryption failed: $e');
      rethrow;
    }
  }

  Future<Uint8List> decryptFile(Uint8List encryptedData) async {
    try {
      if (_key == null || _salt == null) {
        await initialize();
      }
      
      final algorithm = AesGcm.with256bits();
      
      // Extract nonce, ciphertext, and mac
      final nonce = Nonce(encryptedData.sublist(0, 12));
      final cipherText = encryptedData.sublist(12, encryptedData.length - 16);
      final mac = Mac(encryptedData.sublist(encryptedData.length - 16));
      
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
      
      return await algorithm.decrypt(
        secretBox,
        secretKey: _key!,
        aad: utf8.encode('hemoai_file_encryption'),
      );
    } catch (e) {
      _logger.e('File decryption failed: $e');
      rethrow;
    }
  }

  Future<void> rotateEncryptionKey() async {
    try {
      _logger.i('Rotating encryption key');
      
      // Generate new key and salt
      await _generateNewKeyAndSalt();
      
      // Note: In a real application, you would need to re-encrypt all existing data
      // with the new key. This is a complex operation that should be done carefully.
      
      _logger.i('Encryption key rotated successfully');
    } catch (e) {
      _logger.e('Failed to rotate encryption key: $e');
      rethrow;
    }
  }

  Future<bool> isInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyBytes = prefs.getString(_keyStorageKey);
      final saltBytes = prefs.getString(_saltStorageKey);
      
      return keyBytes != null && saltBytes != null;
    } catch (e) {
      _logger.e('Failed to check encryption initialization: $e');
      return false;
    }
  }
}
