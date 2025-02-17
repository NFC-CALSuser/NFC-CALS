import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';

class NFCService {
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<String> readNFCTag() async {
    String result = '';
    
    try {
      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        try {
          var ndef = Ndef.from(tag);
          if (ndef == null) {
            result = 'Tag is not NDEF formatted';
            await NfcManager.instance.stopSession();
            return;
          }

          var ndefMessage = await ndef.read();
          if (ndefMessage.records.isEmpty) {
            result = 'No NDEF records found';
            await NfcManager.instance.stopSession();
            return;
          }

          var record = ndefMessage.records.first;
          if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
            // Skip the language code (first 3 bytes) for Text records
            var payload = record.payload;
            if (payload.length > 3) {
              result = String.fromCharCodes(payload.sublist(3));
            }
          }
          
          await NfcManager.instance.stopSession();
        } catch (e) {
          result = 'Error reading tag: $e';
          await NfcManager.instance.stopSession();
        }
      });
    } catch (e) {
      result = 'Error starting NFC session: $e';
    }
    
    return result;
  }

  static Future<bool> writeNFCTag(String data) async {
    bool success = false;
    
    try {
      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        try {
          var ndef = Ndef.from(tag);
          if (ndef == null) {
            await NfcManager.instance.stopSession(errorMessage: 'Tag is not NDEF formatted');
            return;
          }

          if (!ndef.isWritable) {
            await NfcManager.instance.stopSession(errorMessage: 'Tag is not writable');
            return;
          }

          // Create a proper NDEF record with language code
          var languageCode = [0x02, 0x65, 0x6E]; // en
          var payload = [...languageCode, ...data.codeUnits];
          var record = NdefRecord(
            typeNameFormat: NdefTypeNameFormat.nfcWellknown,
            type: Uint8List.fromList([0x54]), // 'T' for text record
            identifier: Uint8List.fromList([]),
            payload: Uint8List.fromList(payload),
          );

          var message = NdefMessage([record]);
          await ndef.write(message);
          success = true;
          await NfcManager.instance.stopSession();
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: e.toString());
        }
      });
    } catch (e) {
      print('Error starting NFC session: $e');
    }
    
    return success;
  }
}
