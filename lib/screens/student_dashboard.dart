import 'package:flutter/material.dart';
import '../nfc_service.dart';
import 'dart:convert';
import './login_screen.dart'; // Add this import

class StudentDashboard extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentDashboard({
    super.key,
    required this.studentData,
  });

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _markAttendance(BuildContext context) async {
    bool available = await NFCService.isAvailable();
    if (!available) {
      _showMessage(context, 'NFC is not available on this device');
      return;
    }

    _showMessage(context, 'Hold your device near the classroom NFC tag');
    String result = await NFCService.readNFCTag();

    try {
      // Parse the JSON data from the NFC tag
      Map<String, dynamic> sessionData = jsonDecode(result);

      if (sessionData['status'] == 'active') {
        DateTime startTime = DateTime.parse(sessionData['startTime']);
        DateTime now = DateTime.now();
        Duration difference = now.difference(startTime);

        // Check if within the 50-minute window
        if (difference.inMinutes <= int.parse(sessionData['duration'])) {
          _showMessage(context,
              'Attendance marked successfully for ${sessionData['instructor']}\'s class!');
        } else {
          _showMessage(
              context, 'Session has expired. Please contact your instructor.');
        }
      } else {
        _showMessage(context, 'No active session found on this tag');
      }
    } catch (e) {
      _showMessage(
          context, 'Invalid session data. Please contact your instructor.');
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    return false;
  }

  void _handleSignOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KSU-Attendance System'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleSignOut(context),
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
                // NFC Card Design
                GestureDetector(
                  onTap: () => _markAttendance(context),
                  child: Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue, Colors.blueAccent],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Icon(
                            Icons.wifi_tethering,
                            size: 30,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Student ID Card',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                studentData['name'], // Use data from JSON
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                studentData['id']
                                    .toString(), // Use data from JSON
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.touch_app,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tap to mark attendance',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
