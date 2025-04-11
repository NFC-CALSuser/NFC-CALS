import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import '../services/nfc_security_service.dart';
import '../services/encryption_service.dart';

class NFCService {
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<bool> writeNFCTag(String data) async {
    Completer<bool> completer = Completer<bool>();

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
            nfcData['uid'] = uid;
            final timestamp = DateTime.now().toIso8601String();
            nfcData['timestamp'] = timestamp;
            
            // Encrypt the data
            final encryptedData = await EncryptionService.encryptData(jsonEncode(nfcData));
            
            // Create NDEF message with encrypted data
            var ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              throw Exception('Tag is not NDEF formatted or not writable');
            }

            final message = NdefMessage([
              NdefRecord(
                typeNameFormat: NdefTypeNameFormat.nfcWellknown,
                type: Uint8List.fromList([0x54]),
                identifier: Uint8List.fromList([]),
                payload: Uint8List.fromList([
                  0x02,
                  0x65,
                  0x6E,
                  ...jsonEncode(encryptedData).codeUnits,
                ]),
              ),
            ]);

            await ndef.write(message);
            print('Write completed successfully');

            completer.complete(true);
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

  static Future<String> readNFCTag() async {
    Completer<String> completer = Completer<String>();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            var ndef = Ndef.from(tag);
            if (ndef == null) {
              throw Exception('Tag is not NDEF formatted');
            }

            final message = await ndef.read();
            final record = message.records.first;
            final payload = String.fromCharCodes(record.payload.sublist(3));
            
            // Decrypt the data
            final encryptedData = jsonDecode(payload);
            final decryptedData = await EncryptionService.decryptData(
              encryptedData['data'],
              encryptedData['iv']
            );

            completer.complete(jsonEncode(decryptedData));
            await NfcManager.instance.stopSession();
          } catch (e) {
            print('Error reading tag: $e');
            completer.completeError(e);
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      print('Error starting NFC session: $e');
      completer.completeError(e);
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
