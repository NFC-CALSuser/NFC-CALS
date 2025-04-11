import 'package:flutter/material.dart';
import '../nfc_service.dart';
import 'dart:convert';
import './login_screen.dart'; 
import 'package:http/http.dart' as http;
import '../services/encryption_service.dart'; 

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
    try {
      bool available = await NFCService.isAvailable();
      if (!available) {
        _showMessage(context, 'NFC is not available on this device');
        return;
      }

      _showMessage(context, 'Hold your device near the classroom NFC tag');
      String result = await NFCService.readNFCTag();
      print('NFC Tag Read Result: $result');

      final tagData = jsonDecode(result);
      print('Tag Data: $tagData');

      if (tagData['status'] == 'active') {
        final recordId = tagData['record_id'];
        print('Fetching attendance record: $recordId');
        
        // Add retry mechanism for fetching attendance record
        int retries = 3;
        http.Response? getResponse;
        
        while (retries > 0) {
          try {
            getResponse = await http.get(
              Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/attendance/$recordId'),
            );
            if (getResponse.statusCode == 200) break;
            
            retries--;
            if (retries > 0) {
              await Future.delayed(const Duration(seconds: 1));
              print('Retrying attendance record fetch... ($retries attempts left)');
            }
          } catch (e) {
            print('Error fetching attendance record: $e');
          }
        }

        if (getResponse == null || getResponse.statusCode != 200) {
          throw Exception('Failed to fetch attendance record after multiple attempts');
        }

        final currentRecord = jsonDecode(getResponse.body);
        print('Current Record: $currentRecord');

        // Get current student IDs
        List<String> currentStudentIds = List<String>.from(currentRecord['students_ids'] ?? []);
        
        if (!currentStudentIds.contains(studentData['id'].toString())) {
          currentStudentIds.add(studentData['id'].toString());

          final updateResponse = await http.patch(
            Uri.parse('https://cals-server-12aff9883ee5.herokuapp.com/attendance/$recordId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'encrypted_data': currentRecord['encrypted_data'],
              'students_ids': currentStudentIds,
              'status': currentRecord['status']
            }),
          );

          if (updateResponse.statusCode == 200) {
            _showMessage(context, 'Attendance marked successfully!');
            return;
          } else {
            throw Exception('Failed to update attendance record: ${updateResponse.statusCode}');
          }
        } else {
          _showMessage(context, 'Attendance already marked for this session');
          return;
        }
      } else {
        _showMessage(context, 'No active session found');
      }
    } catch (e) {
      print('Error marking attendance: $e');
      _showMessage(context, 'Error marking attendance. Please try again.');
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

  Future<List<Map<String, dynamic>>> _fetchAbsenceData() async {
    final response = await http.get(Uri.parse(
        'https://cals-server-12aff9883ee5.herokuapp.com/students_view'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> readOnlyData = jsonData['read_only'] as List<dynamic>;
      final targetStudentId = studentData['id'].toString();

      final studentRecord = readOnlyData.firstWhere(
          (s) => s['student_id'] == targetStudentId,
          orElse: () => {'courses': []});

      return (studentRecord['courses'] as List)
          .map((course) => {
                'course': course['course'],
                'date': DateTime.now().toString().split(' ')[0],
                'percentage': course['current_percentage'],
                'absenceDates': (course['absence_dates'] as List)
                    .map((date) => date.toString())
                    .toList(),
              })
          .toList()
          .cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load absence data');
    }
  }

  void _showAbsencePercentages(BuildContext context) {
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
                  Icon(Icons.bar_chart, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Absence Percentages',
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
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAbsenceData(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data![index];
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
                                      Icons.school,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      data['course'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          data['date'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPercentageColor(
                                            data['percentage']),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        data['percentage'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                      children: [
                                        const Text(
                                          'Absence Dates:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if ((data['absenceDates'] as List)
                                            .isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Text(
                                              'No absences recorded',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        else
                                          ...List<String>.from(
                                                  data['absenceDates'])
                                              .map((date) => Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.event_busy,
                                                          size: 16,
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          date,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                              ,
                                      ],
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
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
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
                                studentData['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                studentData['id'].toString(),
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
                        onTap: () => _showAbsencePercentages(context),
                        borderRadius: BorderRadius.circular(15),
                        splashColor: Colors.white.withOpacity(0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                'Absence Percentages',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Icon(
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
