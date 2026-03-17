import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class EncryptedFileStore {
  static const _keyName = 'note0_local_key_v1';
  static const _fileName = 'notes.enc.json';

  EncryptedFileStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? _defaultSecureStorage();

  final FlutterSecureStorage _secureStorage;
  final _cipher = AesGcm.with256bits();

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<SecretKey> _getOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) {
      return SecretKey(base64Decode(existing));
    }

    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(key: _keyName, value: base64Encode(bytes));
    return key;
  }

  Future<Map<String, Object?>?> readJson() async {
    final file = await _file();
    if (!await file.exists()) return null;

    final raw = await file.readAsString();
    if (raw.isEmpty) return null;

    final payload = jsonDecode(raw) as Map<String, Object?>;
    final nonce = base64Decode(payload['n'] as String);
    final cipherText = base64Decode(payload['c'] as String);
    final macBytes = base64Decode(payload['m'] as String);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

    final key = await _getOrCreateKey();
    final clearBytes = await _cipher.decrypt(box, secretKey: key);
    final clearText = utf8.decode(clearBytes);
    return jsonDecode(clearText) as Map<String, Object?>;
  }

  Future<void> writeJson(Map<String, Object?> value) async {
    final clearText = jsonEncode(value);
    final clearBytes = utf8.encode(clearText);
    final key = await _getOrCreateKey();
    final box = await _cipher.encrypt(clearBytes, secretKey: key);

    final payload = <String, Object?>{
      'n': base64Encode(box.nonce),
      'c': base64Encode(box.cipherText),
      'm': base64Encode(box.mac.bytes),
      'v': 1,
    };

    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(payload), flush: true);
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }
}

FlutterSecureStorage _defaultSecureStorage() {
  return const FlutterSecureStorage();
}
