import 'package:flutter/material.dart';
import 'dart:convert';
import '../nfc_service.dart';
import 'login_screen.dart';

class InstructorDashboard extends StatefulWidget {
  final String instructorName;

  const InstructorDashboard({
    super.key,
    required this.instructorName,
  });

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  String? selectedClass;
  bool _isStartingSession = false;

  // Hardcoded classes from data.json
  final List<String> classrooms = ['G-090', 'G-091', 'G-092'];

  Future<void> _startSession() async {
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a classroom')),
      );
      return;
    }

    setState(() => _isStartingSession = true);

    try {
      // Create session data
      final sessionData = {
        'status': 'active',
        'instructor': widget.instructorName,
        'classroom': selectedClass,
        'startTime': DateTime.now().toIso8601String(),
        'duration': '50', // 50-minute session
      };

      // Convert to JSON string
      final jsonData = jsonEncode(sessionData);

      // Write to NFC tag
      bool isAvailable = await NFCService.isAvailable();
      if (!isAvailable) {
        throw Exception('NFC is not available on this device');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hold your device near the NFC tag')),
      );

      bool success = await NFCService.writeNFCTag(jsonData);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session started successfully')),
        );
      } else {
        throw Exception('Failed to write to NFC tag');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isStartingSession = false);
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    return false;
  }

  void _handleSignOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KSU-Attendance System'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleSignOut,
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
                Text(
                  'Welcome, ${widget.instructorName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Start New Session',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButton<String>(
                        value: selectedClass,
                        hint: const Text('Select Classroom'),
                        isExpanded: true,
                        items: classrooms.map((String classroom) {
                          return DropdownMenuItem<String>(
                            value: classroom,
                            child: Text(classroom),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() => selectedClass = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isStartingSession ? null : _startSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_outlined),
                            const SizedBox(width: 8),
                            Text(_isStartingSession
                                ? 'Starting...'
                                : 'Start Session'),
                          ],
                        ),
                      ),
                    ],
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
