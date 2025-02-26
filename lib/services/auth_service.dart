import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      'https://nfc-calsuser.github.io/NFC-CALS/NFC-Server/data';

  static Future<Map<String, dynamic>?> login(String id, String password) async {
    try {
      // Fetch both student and instructor data
      final studentsResponse =
          await http.get(Uri.parse('$baseUrl/students.json'));
      final instructorsResponse =
          await http.get(Uri.parse('$baseUrl/instructors.json'));

      if (studentsResponse.statusCode != 200 ||
          instructorsResponse.statusCode != 200) {
        throw Exception('Failed to load user data');
      }

      final students = json.decode(studentsResponse.body)['students'] as List;
      final instructors =
          json.decode(instructorsResponse.body)['instructors'] as List;

      // Check instructors first
      for (var instructor in instructors) {
        if (instructor['id'].toString() == id &&
            instructor['password'] == password) {
          return {
            'type': 'instructor',
            'data': instructor,
          };
        }
      }

      // Then check students
      for (var student in students) {
        if (student['id'].toString() == id && student['password'] == password) {
          return {
            'type': 'student',
            'data': student,
          };
        }
      }

      // Admin credentials
      if (id == 'admin' && password == 'admin123') {
        return {
          'type': 'admin',
          'data': {'name': 'Administrator'}
        };
      }

      return null;
    } on SocketException {
      throw const ConnectionException('No internet connection');
    } on HttpException {
      throw const ConnectionException('Could not connect to the server');
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
  }

  // Utility method to fetch courses
  static Future<List<dynamic>> getCourses() async {
    final response = await http.get(Uri.parse('$baseUrl/courses.json'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['courses'];
    }
    throw Exception('Failed to load courses');
  }

  // Utility method to fetch classes
  static Future<List<dynamic>> getClasses() async {
    final response = await http.get(Uri.parse('$baseUrl/classes.json'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['classes'];
    }
    throw Exception('Failed to load classes');
  }
}

class ConnectionException implements Exception {
  final String message;
  const ConnectionException(this.message);
}
