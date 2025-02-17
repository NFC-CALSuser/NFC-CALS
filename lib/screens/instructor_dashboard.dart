import 'package:flutter/material.dart';
import '../nfc_service.dart';
import 'dart:convert';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    bool available = await NFCService.isAvailable();
    if (!available) {
      _showMessage(context, 'NFC is not available on this device');
      return;
    }

    // this will be replaced with actual session data from data.json :) 
    final sessionData = {
      'instructor': 'Dr. Fahad M Alqahtani',
      'startTime': DateTime.now().toString(),
      'duration': '50', // minutes
      'status': 'active'
    };

    // Convert to JSON string
    String dataToWrite = jsonEncode(sessionData);

    _showMessage(context, 'Hold your device near the classroom NFC tag');
    bool success = await NFCService.writeNFCTag(dataToWrite);
    
    if (success) {
      _showMessage(context, 'Session started successfully! Tag is reserved for 50 minutes');
    } else {
      _showMessage(context, 'Failed to start session. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              const SizedBox(height: 20),
              const Text(
                'Dr. Fahad M Alqahtani',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: ElevatedButton(
                      onPressed: () => _startSession(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.play_circle,
                              size: 50, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'Start\nSession',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle view attendance reports
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.assessment, size: 50, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'View\nReports',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
