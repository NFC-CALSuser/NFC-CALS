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

  static Future<Map<String, String>> encryptData(String data) async {
    try {
      // Generate IV
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // Encrypt data
      final encrypted = _encrypter.encrypt(data, iv: iv);
      
      return {
        'iv': iv.base64,
        'data': encrypted.base64
      };
    } catch (e) {
      print('Encryption error: $e');
      throw Exception('Failed to encrypt data');
    }
  }

  static Map<String, dynamic> decryptData(String encryptedData, String ivString) {
    try {
      final iv = encrypt.IV.fromBase64(ivString);
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      return jsonDecode(decrypted);
    } catch (e) {
      print('Decryption error: $e');
      throw Exception('Failed to decrypt data');
    }
  }

  // Add these methods to handle string encryption/decryption
  static Future<String> encryptString(String text) async {
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter.encrypt(text, iv: iv);
      
      return base64.encode(
        iv.bytes + encrypted.bytes
      );
    } catch (e) {
      print('String encryption error: $e');
      throw Exception('Failed to encrypt string');
    }
  }

  static Future<String> decryptString(String encryptedText) async {
    try {
      final bytes = base64.decode(encryptedText);
      final iv = encrypt.IV(bytes.sublist(0, 16));
      final encrypted = encrypt.Encrypted(bytes.sublist(16));
      
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('String decryption error: $e');
      throw Exception('Failed to decrypt string');
    }
  }
}
