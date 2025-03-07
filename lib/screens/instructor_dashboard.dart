import 'package:flutter/material.dart';
import 'dart:convert';
import '../nfc_service.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>> _fetchAttendanceData() async {
    final response = await http.get(Uri.parse(
        'https://cals-server-12aff9883ee5.herokuapp.com/instructor_view'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['20242024']['courses'];
    } else {
      throw Exception('Failed to load attendance data');
    }
  }

  void _showAttendanceHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Attendance History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _fetchAttendanceData(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          String courseCode =
                              snapshot.data!.keys.elementAt(index);
                          Map<String, dynamic> courseData =
                              snapshot.data![courseCode]['students'];

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[50]!, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                title: Row(
                                  children: [
                                    const Icon(
                                      Icons.class_,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      courseCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          courseData.entries.map((student) {
                                        return Card(
                                          color: Colors.grey[50],
                                          child: ExpansionTile(
                                            title: Text(
                                                student.value['student_name']),
                                            subtitle: Text(
                                              'Absence: ${student.value['current_percentage']}',
                                              style: TextStyle(
                                                color: _getPercentageColor(
                                                    student.value[
                                                        'current_percentage']),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Student ID: ${student.key}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'Absence Dates:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    ...List<String>.from(student
                                                                .value[
                                                            'absence_dates'])
                                                        .map((date) => Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          4),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .event_busy,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .redAccent,
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 8),
                                                                  Text(date),
                                                                ],
                                                              ),
                                                            ))
                                                        .toList(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPercentageColor(String percentage) {
    final value = int.parse(percentage.replaceAll('%', ''));
    if (value <= 5) return Colors.green;
    if (value <= 10) return Colors.orange;
    return Colors.red;
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
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _showAttendanceHistory(context),
                        borderRadius: BorderRadius.circular(15),
                        splashColor: Colors.white.withOpacity(0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_edu,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 15),
                              Text(
                                'View Attendance History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 15),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
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
