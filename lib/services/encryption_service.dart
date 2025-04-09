import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../services/config_service.dart';

class EncryptionService {
  static late encrypt.Key _key;
  static late encrypt.IV _iv;
  static late encrypt.Encrypter _encrypter;

  static Future<void> initialize() async {
    final keyString = ConfigService.encryptionKey;
    _key = encrypt.Key.fromUtf8(keyString);
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  static Map<String, dynamic> decryptData(String encryptedData, String ivString) {
    try {
      final iv = encrypt.IV.fromBase64(ivString);
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      return jsonDecode(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }
}