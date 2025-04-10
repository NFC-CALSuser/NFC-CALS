import 'dart:convert';
import 'dart:typed_data'; // Add this import
import 'package:crypto/crypto.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
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
      // Try NfcA first
      final nfcA = NfcA.from(tag);
      if (nfcA != null) {
        final uidBytes = nfcA.identifier;
        return uidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }

      // Try other tag types if NfcA fails
      final identifier = tag.data['mifareclassic']?['identifier'] as Uint8List? ??
                        tag.data['mifareultralight']?['identifier'] as Uint8List? ??
                        tag.data['isodep']?['identifier'] as Uint8List?;
      
      if (identifier != null) {
        return identifier.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }

      throw Exception('Unable to get tag UID');
    } catch (e) {
      print('Error getting tag UID: $e');
      return null;
    }
  }
}