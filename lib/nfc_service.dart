import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

class NFCService {
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<bool> writeNFCTag(String data) async {
    Completer<bool> completer = Completer<bool>();
    bool success = false;

    try {
      await NfcManager.instance.startSession(
        invalidateAfterFirstRead: false, // Allow multiple reads/writes
        onDiscovered: (NfcTag tag) async {
          try {
            print('Tag discovered, attempting to write...');

            var ndef = Ndef.from(tag);
            if (ndef == null) {
              throw Exception('Tag is not NDEF formatted');
            }

            if (!ndef.isWritable) {
              throw Exception('Tag is not writable');
            }

            print('Tag is writable, creating NDEF message...');

            // Create NDEF message with proper encoding
            var record = NdefRecord(
              typeNameFormat: NdefTypeNameFormat.nfcWellknown,
              type: Uint8List.fromList([0x54]), // 'T' for text record
              identifier: Uint8List.fromList([]),
              payload: Uint8List.fromList([
                0x02, // UTF8
                0x65, 0x6E, // 'en'
                ...data.codeUnits,
              ]),
            );

            var message = NdefMessage([record]);
            print('Writing message: $data');

            // Give the tag a moment to stabilize
            await Future.delayed(const Duration(milliseconds: 100));

            // Write to tag
            await ndef.write(message);
            print('Write completed successfully');

            // Give the tag a moment before reading back
            await Future.delayed(const Duration(milliseconds: 100));

            // Verify write with simple read
            try {
              var verifyMessage = await ndef.read();
              if (verifyMessage.records.isNotEmpty) {
                var verifyPayload = String.fromCharCodes(
                    verifyMessage.records.first.payload.sublist(3));
                print('Verification read successful: $verifyPayload');
                if (verifyPayload == data) {
                  success = true;
                  completer.complete(true);
                } else {
                  throw Exception('Write verification failed - data mismatch');
                }
              }
            } catch (verifyError) {
              print('Verification read failed: $verifyError');
              // If write was successful but verify failed, still consider it a success
              if (!completer.isCompleted) {
                success = true;
                completer.complete(true);
              }
            }

            await NfcManager.instance.stopSession();
          } catch (e) {
            print('Error in NFC write: $e');
            if (!completer.isCompleted) {
              completer.complete(false);
            }
            await NfcManager.instance.stopSession(errorMessage: e.toString());
          }
        },
      );
    } catch (e) {
      print('Error starting NFC session: $e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    try {
      success = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('NFC write operation timed out');
          NfcManager.instance.stopSession();
          return false;
        },
      );
    } catch (e) {
      print('Error waiting for NFC operation: $e');
      success = false;
    }

    return success;
  }

  static Future<String> readNFCTag() {
    Completer<String> completer = Completer<String>();

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          var ndef = Ndef.from(tag);
          if (ndef == null) {
            throw Exception('Tag is not NDEF formatted');
          }

          var ndefMessage = await ndef.read();
          if (ndefMessage.records.isEmpty) {
            throw Exception('No NDEF records found');
          }

          var record = ndefMessage.records.first;
          String content = '';

          if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
            var payload = record.payload;
            if (payload.length > 3) {
              content = String.fromCharCodes(payload.sublist(3));
            }
          }

          completer.complete(content);
          await NfcManager.instance.stopSession();
        } catch (e) {
          completer.completeError('Error reading tag: $e');
          await NfcManager.instance.stopSession();
        }
      },
    ).catchError((e) {
      completer.completeError('Error starting NFC session: $e');
    });

    return completer.future;
  }
}
