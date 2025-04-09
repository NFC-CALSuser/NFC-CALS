import 'package:http/http.dart' as http;
import 'dart:convert';

class ConfigService {
  static const String baseUrl = 'https://nfc-calsuser.github.io/NFC-CALS';
  static const String API_URL = '$baseUrl/NFC-Server/data/APIs.json';
  
  static String? _hmacKey;
  static String? _nfcPassword;
  static String? _encryptionKey;

  static Future<void> initialize() async {
    try {
      final response = await http.get(Uri.parse(API_URL));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _hmacKey = data['hmac_key'];
        _nfcPassword = data['nfc_password'];
        _encryptionKey = data['encryption_key'];
      } else {
        throw Exception('Failed to load API configuration');
      }
    } catch (e) {
      print('Error initializing config: $e');
      throw Exception('Failed to initialize configuration');
    }
  }

  // Getter for HMAC key
  static String get hmacKey {
    if (_hmacKey == null) {
      throw Exception('HMAC key not initialized');
    }
    return _hmacKey!;
  }

  // Getter for NFC password
  static String get nfcPassword {
    if (_nfcPassword == null) {
      throw Exception('NFC password not initialized');
    }
    return _nfcPassword!;
  }

  // Getter for encryption key
  static String get encryptionKey {
    if (_encryptionKey == null) {
      throw Exception('Encryption key not initialized');
    }
    return _encryptionKey!;
  }
}
