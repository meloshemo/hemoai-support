import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/utils/backup_encryption.dart';

void main() {
  test('backup encryption roundtrip', () async {
    final data = Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));
    final pwd = 'secret123!';
    final enc = await BackupEncryption.encryptBytes(data, pwd);
    expect(enc.length, greaterThan(data.length));
    final dec = await BackupEncryption.decryptBytes(enc, pwd);
    expect(dec, data);
  });

  test('backup encryption wrong password fails', () async {
    final data = Uint8List.fromList([1,2,3,4,5,6]);
    final enc = await BackupEncryption.encryptBytes(data, 'pwd1');
    expect(() async => await BackupEncryption.decryptBytes(enc, 'pwd2'), throwsA(isA<FormatException>()));
  });
}
