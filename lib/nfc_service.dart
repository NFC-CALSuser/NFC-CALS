import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import '../services/nfc_security_service.dart';

class NFCService {
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<bool> writeNFCTag(String data) async {
    Completer<bool> completer = Completer<bool>();
    bool success = false;

    try {
      final nfcData = jsonDecode(data) as Map<String, dynamic>;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            print('Tag discovered, attempting to write...');

            // Get tag UID
            final uid = await NFCSecurityService.getTagUID(tag);
            if (uid == null) {
              throw Exception('Could not read tag UID');
            }

            // Add security data
            final timestamp = DateTime.now().toIso8601String();
            final signature = NFCSecurityService.generateTagSignature(
                uid, jsonEncode(nfcData), timestamp);

            // Add security information to NFC data with explicit typing
            final Map<String, dynamic> secureData = {
              ...nfcData,
              'uid': uid,
              'timestamp': timestamp,
              'signature': signature,
            };

            var ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              throw Exception('Tag is not NDEF formatted or not writable');
            }

            // Create and write NDEF message
            final message = NdefMessage([
              NdefRecord(
                typeNameFormat: NdefTypeNameFormat.nfcWellknown,
                type: Uint8List.fromList([0x54]),
                identifier: Uint8List.fromList([]),
                payload: Uint8List.fromList([
                  0x02,
                  0x65,
                  0x6E,
                  ...jsonEncode(secureData).codeUnits,
                ]),
              ),
            ]);

            await ndef.write(message);
            print('Write completed successfully');

            // Verify write
            final verifyResult = await _verifyWrite(tag, secureData);
            success = verifyResult;
            completer.complete(verifyResult);

            await NfcManager.instance.stopSession();
          } catch (e) {
            print('Error in NFC write: $e');
            completer.complete(false);
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      print('Error starting NFC session: $e');
      completer.complete(false);
    }

    return completer.future;
  }

  static Future<bool> _verifyWrite(
      NfcTag tag, Map<String, dynamic> expectedData) async {
    try {
      final uid = await NFCSecurityService.getTagUID(tag);
      if (uid == null || uid != expectedData['uid']) {
        return false;
      }

      var ndef = Ndef.from(tag);
      if (ndef == null) return false;

      var message = await ndef.read();
      var record = message.records.first;
      var payload = String.fromCharCodes(record.payload.sublist(3));
      var readData = jsonDecode(payload);

      return NFCSecurityService.verifyTagSignature(
          readData['uid'],
          jsonEncode(Map.from(readData)..remove('signature')),
          readData['timestamp'],
          readData['signature']);
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }

  static Future<String> readNFCTag() async {
    Completer<String> completer = Completer<String>();

    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            var ndef = Ndef.from(tag);
            if (ndef == null) {
              throw Exception('Tag is not NDEF formatted');
            }

            final uid = await NFCSecurityService.getTagUID(tag);
            if (uid == null) {
              throw Exception('Could not read tag UID');
            }

            var message = await ndef.read();
            var record = message.records.first;
            var payload = String.fromCharCodes(record.payload.sublist(3));
            var data = jsonDecode(payload);

            // Verify tag authenticity
            if (data['uid'] != uid) {
              throw Exception('Tag UID mismatch - possible cloned tag');
            }

            final isValid = NFCSecurityService.verifyTagSignature(
                data['uid'],
                jsonEncode(Map.from(data)..remove('signature')),
                data['timestamp'],
                data['signature']);

            if (!isValid) {
              throw Exception('Invalid tag signature - possible cloned tag');
            }

            completer.complete(payload);
            await NfcManager.instance.stopSession();
          } catch (e) {
            completer.completeError('Error reading tag: $e');
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      completer.completeError('Error starting NFC session: $e');
    }

    return completer.future;
  }
}

void processNFCData() async {
  try {
    String result = await NFCService.readNFCTag();
    // Process verified data
  } catch (e) {
    if (e.toString().contains('cloned tag')) {
      // Handle potential cloning attempt
      _showNFCMessage('Security Alert: Possible cloned tag detected', isSuccess: false);
    }
  }
}

void _showNFCMessage(String message, {required bool isSuccess}) {
  print(message);
}
