import 'package:flutter/material.dart';
import '../nfc_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _readTag(BuildContext context) async {
    bool available = await NFCService.isAvailable();
    if (!available) {
      _showMessage(context, 'NFC is not available on this device');
      return;
    }

    _showMessage(context, 'Hold your device near an NFC tag');
    String result = await NFCService.readNFCTag();
    _showMessage(context, 'Read result: $result');
  }

  Future<void> _writeTag(BuildContext context) async {
    bool available = await NFCService.isAvailable();
    if (!available) {
      _showMessage(context, 'NFC is not available on this device');
      return;
    }

    String dataToWrite = 'G-90'; // Example
    _showMessage(context, 'Hold your device near an NFC tag');
    bool success = await NFCService.writeNFCTag(dataToWrite);
    _showMessage(context, success ? 'Write successful' : 'Write failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ksu_shieldlogo_colour_rgb.png',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 45),
              Container(
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: () => _readTag(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('Read from Tag'),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                color: Colors.white,
                child: ElevatedButton(
                  onPressed: () => _writeTag(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('Write to Tag'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
