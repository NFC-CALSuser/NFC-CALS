import 'package:flutter/material.dart';
import '../nfc_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Future<void> _handleReadTag() async {
    bool isAvailable = await NFCService.isAvailable();
    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hold your device near the NFC tag')),
    );

    try {
      String result = await NFCService.readNFCTag();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tag Content'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KSU-Attendance System'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: _handleReadTag,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.nfc, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Read from tag',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                // Handle write to tag action
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Write to tag',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
