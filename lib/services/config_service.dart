import 'package:http/http.dart' as http;
import 'dart:convert';

class ConfigService {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  static const String hmacKey = String.fromEnvironment('HMAC_KEY');

  static Future<void> initialize() async {
    // Verify keys are set
    if (hmacKey.isEmpty) {
      throw Exception('HMAC key not configured');
    }
  }
}
