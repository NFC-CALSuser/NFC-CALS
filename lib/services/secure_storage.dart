import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = FlutterSecureStorage();
  
  static Future<void> storeKey(String key) async {
    await _storage.write(key: 'hmac_key', value: key);
  }
  
  static Future<String?> getKey() async {
    return await _storage.read(key: 'hmac_key');
  }

  static Future<void> storeSessionToken(String token) async {
    await _storage.write(key: 'session_token', value: token);
  }

  static Future<String?> getSessionToken() async {
    return await _storage.read(key: 'session_token');
  }

  static Future<void> updateLastRotationTime() async {
    await _storage.write(
      key: 'last_key_rotation',
      value: DateTime.now().toIso8601String(),
    );
  }

  static Future<DateTime?> getLastRotationTime() async {
    final timeStr = await _storage.read(key: 'last_key_rotation');
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}