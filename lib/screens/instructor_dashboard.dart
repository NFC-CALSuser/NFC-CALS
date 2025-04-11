import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import '../nfc_service.dart';
import '../services/encryption_service.dart'; // Import EncryptionService
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import '../widgets/nfc_instruction_overlay.dart';

class InstructorDashboard extends StatefulWidget {
  final String instructorName;
  final String instructorId; // Add this

  const InstructorDashboard({
    super.key,
    required this.instructorName,
    required this.instructorId, // Add this
  });

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  String? selectedClass;
  String? selectedCourse;
  bool _isStartingSession = false;
  List<String> courses = []; // Change from final to regular List
  bool _hasActiveSession = false;
  String? _activeSessionId;
  Map<String, dynamic>? _activeSessionData;
  int _remainingMinutes = 50;
  Timer? _sessionTimer;
  final TextEditingController _studentIdController = TextEditingController();
  bool _isTagVerified = false;
  bool _isWritingToTag = false;
  int _writeAttempts = 0;
  final int _maxWriteAttempts = 3;
  OverlayEntry? _overlayEntry;

  // Hardcoded classes from data.json
  final List<String> classrooms = ['G-090', 'G-091', 'G-092'];

  @override
  void initState() {
    super.initState();
    _loadInstructorCourses();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _sessionTimer?.cancel();
    _hideNFCMessage();
    super.dispose();
  }

  Future<void> _loadInstructorCourses() async {
    try {
      final response = await http.get(Uri.parse(
          'https://cals-server-12aff9883ee5.herokuapp.com/instructor_view'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final coursesData = jsonData['20242024']['courses'];
        if (coursesData != null) {
          setState(() {
            // Extract course codes (keys) from the courses object
            courses = List<String>.from(coursesData.keys);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _startSession() async {
    if (selectedClass == null || selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both course and classroom')),
      );
      return;
    }

    setState(() => _isStartingSession = true);

    try {
      final now = DateTime.now();
      final recordId = now.millisecondsSinceEpoch.toString();

      // Prepare session data
      final sessionData = {
        'status': 'active',
        'instructor': widget.instructorId,
        'course': selectedCourse,
        'classroom': selectedClass,
        'startTime': now.toIso8601String(),
        'duration': '50',
        'record_id': recordId,
      };

      // Encrypt session data for server
      final encryptedData = await EncryptionService.encryptData(jsonEncode(sessionData));

      // Create attendance record with encrypted data
      await _createAttendanceRecord(recordId, now, encryptedData);
      print('Attendance record created with ID: $recordId');

      // Write encrypted data to NFC tag
      bool writeSuccess = await NFCService.writeNFCTag(jsonEncode(sessionData));
      
      if (!writeSuccess) {
        // Clean up if write fails
        await http.delete(
          Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/attendance/$recordId'),
        );
        throw Exception('Failed to write to NFC tag');
      }

      // Update state and start countdown
      setState(() {
        _hasActiveSession = true;
        _activeSessionId = recordId;
        _activeSessionData = sessionData;
      });

      _startCountdown();
      _showNFCMessage('Session started successfully', isSuccess: true);
      await Future.delayed(const Duration(seconds: 2));
      _hideNFCMessage();

    } catch (e) {
      print('Error starting session: $e');
      _showNFCMessage('Error: ${e.toString()}', isSuccess: false);
      await Future.delayed(const Duration(seconds: 2));
      _hideNFCMessage();
    } finally {
      setState(() => _isStartingSession = false);
    }
  }

  Future<void> _createAttendanceRecord(String recordId, DateTime startTime, Map<String, String> encryptedSessionData) async {
    print('Creating attendance record...');
    
    try {
      final response = await http.post(
        Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': recordId, // Use plain recordId for now
          'encrypted_data': encryptedSessionData,
          'status': 'active',
          'students_ids': []
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Server response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create attendance record: ${response.body}');
      }

      // Verify record creation
      final verifyResponse = await http.get(
        Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/attendance/$recordId'),
      );

      if (verifyResponse.statusCode != 200) {
        throw Exception('Failed to verify attendance record creation');
      }

      print('Attendance record created successfully');
    } catch (e) {
      print('Error creating attendance record: $e');
      throw e;
    }
  }

  void _startCountdown() {
    _remainingMinutes = 50;
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        if (_remainingMinutes > 0) {
          _remainingMinutes--;
        } else {
          _endSession();
          timer.cancel();
        }
      });
    });
  }

  Future<void> _endSession() async {
    try {
      if (_activeSessionId != null) {
        setState(() => _isStartingSession = true);
        _showNFCMessage('Ending session...', isSuccess: false);

        // Get current attendance record
        final getResponse = await http.get(
          Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/attendance/${_activeSessionId}'),
        );

        if (getResponse.statusCode == 200) {
          final currentRecord = jsonDecode(getResponse.body);
          
          // Update session status to ended first
          final updateResponse = await http.patch(
            Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/attendance/${_activeSessionId}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'status': 'ended',
              'encrypted_data': currentRecord['encrypted_data'],
              'students_ids': currentRecord['students_ids']
            }),
          );

          if (updateResponse.statusCode != 200) {
            throw Exception('Failed to update session status');
          }

          // Process attendance marking
          try {
            // Get instructor view data
            final instructorResponse = await http.get(
              Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/instructor_view'),
            );

            if (instructorResponse.statusCode != 200) {
              throw Exception('Failed to fetch instructor data');
            }

            final instructorData = jsonDecode(instructorResponse.body);
            final courseData = instructorData[widget.instructorId]['courses'][_activeSessionData!['course']];
            
            // Get enrolled students
            final enrolledStudents = courseData['students'].keys.toList();
            final presentStudents = currentRecord['students_ids'];
            
            // Calculate absent students
            final absentStudents = enrolledStudents.where((id) => !presentStudents.contains(id)).toList();

            // Update attendance records
            for (final studentId in absentStudents) {
              final student = courseData['students'][studentId];
              int currentPercentage = int.parse(student['current_percentage'].replaceAll('%', ''));
              currentPercentage += 3;
              student['current_percentage'] = '$currentPercentage%';

              if (student['absence_dates'] == null) {
                student['absence_dates'] = [];
              }
              student['absence_dates'].add(DateTime.now().toIso8601String().split('T')[0]);
            }

            // Update instructor view
            final updateInstructorResponse = await http.put(
              Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/instructor_view'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(instructorData),
            );

            if (updateInstructorResponse.statusCode != 200) {
              throw Exception('Failed to update instructor view');
            }

            setState(() {
              _hasActiveSession = false;
              _activeSessionId = null;
              _activeSessionData = null;
              _sessionTimer?.cancel();
            });
            
            _showNFCMessage('Session ended successfully', isSuccess: true);
            await Future.delayed(const Duration(seconds: 2));
            _hideNFCMessage();
          } catch (e) {
            print('Error processing attendance: $e');
            throw Exception('Failed to process attendance marking');
          }
        } else {
          throw Exception('Failed to fetch current session data');
        }
      }
    } catch (e) {
      print('Error ending session: $e');
      if (!mounted) return;
      _showNFCMessage('Error ending session: ${e.toString()}', isSuccess: false);
      await Future.delayed(const Duration(seconds: 2));
      _hideNFCMessage();
    } finally {
      if (mounted) {
        setState(() => _isStartingSession = false);
      }
    }
  }

  Future<void> _markManualAttendance() async {
    if (!_hasActiveSession) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Student Attendance'),
        content: TextField(
          controller: _studentIdController,
          decoration: const InputDecoration(
            labelText: 'Student ID',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_studentIdController.text.isEmpty) return;

              // Get current attendance record
              final getResponse = await http.get(
                Uri.parse(
                    'https://cals-server-12aff9883ee5.herokuapp.com/attendance/$_activeSessionId'),
              );

              if (getResponse.statusCode == 200) {
                final currentRecord = jsonDecode(getResponse.body);
                final currentStudentIds =
                    List<String>.from(currentRecord['students_ids'] ?? []);

                if (!currentStudentIds.contains(_studentIdController.text)) {
                  currentStudentIds.add(_studentIdController.text);

                  final updateResponse = await http.patch(
                    Uri.parse(
                        'https://cals-server-12aff9883ee5.herokuapp.com/attendance/$_activeSessionId'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'students_ids': currentStudentIds}),
                  );

                  if (updateResponse.statusCode == 200) {
                    _studentIdController.clear();
                    Navigator.pop(context);
                    _showNFCMessage(
                      'Student attendance marked successfully',
                      isSuccess: true,
                    );
                    await Future.delayed(const Duration(seconds: 2));
                    _hideNFCMessage();
                    return;
                  }
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Student already marked for this session')),
                  );
                  return;
                }
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to mark attendance')),
              );
            },
            child: const Text('Mark Attendance'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasActiveSession) {
      // Show confirmation dialog if there's an active session
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Active Session'),
          content: const Text('Do you want to end the current session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _endSession();
                if (!mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('End Session'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
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
      final instructorView = jsonData['20242024'];
      if (instructorView == null) {
        throw Exception('Instructor data not found');
      }
      return instructorView['courses'];
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
                                                            )),
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
    if (value <= 15) return Colors.green;
    if (value < 25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope( // Replace WillPopScope with PopScope
      canPop: !_hasActiveSession,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final result = await _onWillPop();
        if (result && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KSU-Attendance System'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleSignOut,
          ),
        ),
        body: SingleChildScrollView(
          // Add ScrollView to prevent overflow
          child: Container(
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
                  if (_hasActiveSession)
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Active Session',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (_isTagVerified)
                                const Icon(Icons.check_circle,
                                    color: Colors.green)
                              else
                                const Icon(Icons.error, color: Colors.red),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Course: ${_activeSessionData?['course']}'),
                          Text(
                              'Classroom: ${_activeSessionData?['classroom']}'),
                          Text('Time Remaining: $_remainingMinutes minutes'),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: _markManualAttendance,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Mark Attendance'),
                              ),
                              ElevatedButton(
                                onPressed: _endSession,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('End Session'),
                              ),
                            ],
                          ),
                          if (_isWritingToTag)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(width: 10),
                                Text(
                                    'Writing to NFC tag (Attempt $_writeAttempts of $_maxWriteAttempts)'),
                              ],
                            ),
                        ],
                      ),
                    )
                  else
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
                            value: selectedCourse,
                            hint: const Text('Select Course'),
                            isExpanded: true,
                            items: courses.map((String course) {
                              return DropdownMenuItem<String>(
                                value: course,
                                child: Text(course),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() => selectedCourse = value);
                            },
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
                            onPressed:
                                _isStartingSession ? null : _startSession,
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
      ),
    );
  }

  void _showWriteAttemptDialog() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 16),
            Text(
                'Writing to NFC tag (Attempt $_writeAttempts of $_maxWriteAttempts).\nHold your device near the tag.'),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<VerificationResult> _verifyNFCTag(Map<String, dynamic> expectedData) async {
    try {
      String result = await NFCService.readNFCTag();
      Map<String, dynamic> tagData = jsonDecode(result);
      
      // Verify essential fields
      if (tagData['record_id'] != expectedData['record_id'] ||
          tagData['course'] != expectedData['course'] ||
          tagData['classroom'] != expectedData['classroom']) {
        return VerificationResult(false, 'Tag data verification failed');
      }
      
      return VerificationResult(true, null);
    } catch (e) {
      return VerificationResult(false, 'Verification error: $e');
    }
  }

  void _showSuccessMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session started successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Add this method to show NFC messages
  void _showNFCMessage(String message, {bool isSuccess = false}) {
    // Remove existing overlay if any
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.15,
        left: 0,
        right: 0,
        child: NFCInstructionOverlay(
          message: message,
          icon: isSuccess ? Icons.check_circle_outline : Icons.nfc,
          color: isSuccess ? Colors.green.shade600 : Colors.blue.shade600,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideNFCMessage() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class VerificationResult {
  final bool verified;
  final String? error;

  VerificationResult(this.verified, this.error);
}
