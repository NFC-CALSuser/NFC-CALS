import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../services/config_service.dart';

class EncryptionService {
  static late encrypt.Key _key;
  static late encrypt.Encrypter _encrypter;

  static Future<void> initialize() async {
    try {
      // Get encryption key and convert to bytes
      final keyString = ConfigService.encryptionKey;
      final keyBytes = _hexStringToBytes(keyString);

      // Create AES key with first 16 bytes
      _key = encrypt.Key(keyBytes.sublist(0, 16));

      // Create encrypter with CBC mode
      _encrypter = encrypt.Encrypter(
        encrypt.AES(
          _key,
          mode: encrypt.AESMode.cbc,
          padding: 'PKCS7',
        ),
      );

      print('Encryption service initialized successfully');
    } catch (e) {
      print('Error initializing encryption service: $e');
      rethrow;
    }
  }

  static Uint8List _hexStringToBytes(String hex) {
    var result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var num = int.parse(hex.substring(i, i + 2), radix: 16);
      result[i ~/ 2] = num;
    }
    return result;
  }

  static Map<String, dynamic> decryptData(
      String encryptedData, String ivString) {
    try {
      print('Decrypting data...');

      // Create IV from base64
      final iv = encrypt.IV.fromBase64(ivString);
      print('IV created successfully');

      // Create encrypted instance
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      print('Encrypted data parsed successfully');

      // Decrypt data
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      print('Data decrypted successfully');

      // Parse JSON
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print('Decryption error: $e');
      throw Exception('Failed to decrypt data');
    }
  }
}
