import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';  // Add this import
import '../services/config_service.dart';

class NFCSecurityService {
  static String generateTagSignature(String uid, String data, String timestamp) {
    final hmac = Hmac(sha256, utf8.encode(ConfigService.hmacKey));
    final signatureData = '$uid:$data:$timestamp';
    final digest = hmac.convert(utf8.encode(signatureData));
    return digest.toString();
  }

  static bool verifyTagSignature(String uid, String data, String timestamp, String signature) {
    final expectedSignature = generateTagSignature(uid, data, timestamp);
    return signature == expectedSignature;
  }

  static Future<String?> getTagUID(NfcTag tag) async {
    try {
      final tech = NfcA.from(tag);
      if (tech == null) return null;
      
      // Get tag UID bytes
      final uidBytes = tech.identifier;
      return uidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    } catch (e) {
      print('Error getting tag UID: $e');
      return null;
    }
  }
}