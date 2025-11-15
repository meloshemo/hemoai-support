import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Minimal AES-GCM helper for optional field encryption before Firestore writes.
///
/// WARNING: Key management is out of scope here. In production, fetch a per-user key
/// from a secure backend (e.g., Firebase Functions config + KMS) and cache it in
/// platform secure storage. Do not hardcode keys in the client.
class FirestoreFieldCrypto {
  static final _algo = AesGcm.with256bits();

  /// Encrypts [plain] with [secretKey]. Returns base64 of nonce+ciphertext+tag.
  static Future<String> encryptString(String plain, SecretKey secretKey) async {
    final nonce = await Future.sync(() => _algo.newNonce());
    final secretBox = await _algo.encrypt(utf8.encode(plain), secretKey: secretKey, nonce: nonce);
    final payload = Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return base64Encode(payload);
  }

  /// Decrypts a base64 payload produced by [encryptString].
  static Future<String> decryptString(String b64, SecretKey secretKey) async {
    final data = base64Decode(b64);
    final nonce = data.sublist(0, 12);
    final mac = Mac(data.sublist(data.length - 16));
    final cipherText = data.sublist(12, data.length - 16);
    final clear = await _algo.decrypt(SecretBox(cipherText, nonce: nonce, mac: mac), secretKey: secretKey);
    return utf8.decode(clear);
  }
  
}
