import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cryptography/cryptography.dart';

class BackupEncryption {
  // File layout (bytes):
  // [ magic(6) = 48 45 4D 4F 45 4E 'HEMOEN' ]
  // [ version(1) = 1 ]
  // [ salt(16) ]
  // [ nonce(12) ]
  // [ ciphertext+tag (AES-GCM) ]
  static const String _magic = 'HEMOEN';
  static const int _version = 1;
  static const int _saltLen = 16;
  static const int _nonceLen = 12;

  static final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );
  static final _algo = AesGcm.with256bits();

  static Future<Uint8List> encryptBytes(Uint8List plain, String password) async {
  final rng = math.Random.secure();
  final salt = _randBytes(rng, _saltLen);
  final nonce = _randBytes(rng, _nonceLen);
    final key = await _deriveKey(password, salt);
    final secretKey = SecretKey(key);
    final result = await _algo.encrypt(plain, secretKey: secretKey, nonce: nonce);
    final magicBytes = utf8.encode(_magic);
    final out = BytesBuilder();
    out.add(magicBytes);
    out.add([_version]);
    out.add(salt);
    out.add(nonce);
    out.add(result.cipherText);
    out.add(result.mac.bytes);
    return Uint8List.fromList(out.takeBytes());
  }

  static Future<Uint8List> decryptBytes(Uint8List data, String password) async {
    final magicBytes = utf8.encode(_magic);
    if (data.length < magicBytes.length + 1 + _saltLen + _nonceLen + 16) {
      throw const FormatException('Invalid encrypted file');
    }
    // Verify magic
    for (int i = 0; i < magicBytes.length; i++) {
      if (data[i] != magicBytes[i]) {
        throw const FormatException('Invalid magic header');
      }
    }
    final version = data[magicBytes.length];
    if (version != _version) {
      throw const FormatException('Unsupported version');
    }
    final offsetSalt = magicBytes.length + 1;
    final salt = data.sublist(offsetSalt, offsetSalt + _saltLen);
    final offsetNonce = offsetSalt + _saltLen;
    final nonce = data.sublist(offsetNonce, offsetNonce + _nonceLen);
    final offsetPayload = offsetNonce + _nonceLen;
    if (offsetPayload >= data.length) {
      throw const FormatException('Invalid payload');
    }
    // Split ciphertext and mac (last 16 bytes default for AES-GCM mac length may be 16)
    if (data.length - offsetPayload < 16) {
      throw const FormatException('Truncated payload');
    }
    final macBytes = data.sublist(data.length - 16);
    final cipherText = data.sublist(offsetPayload, data.length - 16);

    final key = await _deriveKey(password, salt);
    final secretKey = SecretKey(key);
    final mac = Mac(macBytes);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    try {
      final clear = await _algo.decrypt(secretBox, secretKey: secretKey);
      return Uint8List.fromList(clear);
    } catch (e) {
      throw const FormatException('Decryption failed');
    }
  }

  static Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    final pwdBytes = utf8.encode(password);
    final secretKey = await _pbkdf2.deriveKey(secretKey: SecretKey(pwdBytes), nonce: salt);
    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }
  static Uint8List _randBytes(math.Random rand, int len) {
    final bytes = Uint8List(len);
    for (int i = 0; i < len; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }
}
