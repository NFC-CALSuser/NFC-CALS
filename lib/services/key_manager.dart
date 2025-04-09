import '../services/secure_storage.dart';
import '../services/auth_service.dart';

class KeyManager {
  static const keyValidityDuration = Duration(hours: 24);
  
  static Future<String> getCurrentKey() async {
    final storedKey = await SecureStorage.getKey();
    final lastRotation = await SecureStorage.getLastRotationTime();
    
    if (storedKey == null || _shouldRotateKey(lastRotation)) {
      return await _rotateKey();
    }
    return storedKey;
  }
  
  static bool _shouldRotateKey(DateTime? lastRotation) {
    if (lastRotation == null) return true;
    final difference = DateTime.now().difference(lastRotation);
    return difference >= keyValidityDuration;
  }

  static Future<String> _rotateKey() async {
    final deviceId = await _getDeviceId();
    final sessionToken = await SecureStorage.getSessionToken();
    
    if (sessionToken == null) {
      throw Exception('No valid session token');
    }

    final newKey = await AuthService.getSecureKey(
      sessionToken: sessionToken,
      deviceId: deviceId,
    );
    
    await SecureStorage.storeKey(newKey);
    await SecureStorage.updateLastRotationTime();
    return newKey;
  }

  static Future<String> _getDeviceId() async {
    // Implement device ID generation/retrieval
    // You might want to use package:device_info_plus for this
    return 'default_device_id';
  }
}