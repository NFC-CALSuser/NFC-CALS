import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  static const String SECRET_KEY = '4a9c5c2e89f340c399a6a3f3928021f48920a206e09c4336b580bacbb34e3034';
  
  static String generateSessionToken({
    required String recordId,
    required String instructorId,
    required String timestamp,
  }) {
    // Create unique session identifier
    final sessionId = const Uuid().v4();
    
    // Combine data for token generation
    final data = '$recordId:$instructorId:$timestamp:$sessionId';
    
    // Create HMAC signature
    final hmac = Hmac(sha256, utf8.encode(SECRET_KEY));
    final digest = hmac.convert(utf8.encode(data));
    
    // Return base64 encoded token
    return base64Url.encode(utf8.encode('$data:${digest.toString()}'));
  }

  static bool verifySessionToken(String token, String recordId, String instructorId) {
    try {
      // Decode token
      final decoded = utf8.decode(base64Url.decode(token));
      final parts = decoded.split(':');
      
      if (parts.length != 5) return false;
      
      // Extract data
      final tokenRecordId = parts[0];
      final tokenInstructorId = parts[1];
      final timestamp = DateTime.parse(parts[2]);
      final sessionId = parts[3];
      final signature = parts[4];
      
      // Verify data matches
      if (tokenRecordId != recordId || tokenInstructorId != instructorId) {
        return false;
      }
      
      // Check if token is expired (50 minutes)
      if (DateTime.now().difference(timestamp).inMinutes > 50) {
        return false;
      }
      
      // Verify signature
      final data = '$tokenRecordId:$tokenInstructorId:${timestamp.toIso8601String()}:$sessionId';
      final hmac = Hmac(sha256, utf8.encode(SECRET_KEY));
      final expectedSignature = hmac.convert(utf8.encode(data)).toString();
      
      return signature == expectedSignature;
    } catch (e) {
      print('Session token verification failed: $e');
      return false;
    }
  }
}