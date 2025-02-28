import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://nfc-calsuser.github.io/NFC-CALS';
  static const String SECRET_KEY =
      '4a9c5c2e89f340c399a6a3f3928021f48920a206e09c4336b580bacbb34e3034';

  static String hashPassword(String password) {
    final hmac = Hmac(sha256, utf8.encode(SECRET_KEY));
    final digest = hmac.convert(utf8.encode(password));
    return digest.toString();
  }

  static Future<Map<String, dynamic>?> login(String id, String password) async {
    try {
      final studentsResponse =
          await http.get(Uri.parse('$baseUrl/NFC-Server/data/students.json'));
      final instructorsResponse = await http
          .get(Uri.parse('$baseUrl/NFC-Server/data/instructors.json'));

      if (studentsResponse.statusCode == 200 &&
          instructorsResponse.statusCode == 200) {
        final studentsData =
            json.decode(studentsResponse.body)['students'] as List;
        final instructorsData =
            json.decode(instructorsResponse.body)['instructors'] as List;

        final hashedPassword = hashPassword(password);
        print('Input ID: $id'); // Debug print
        print('Hashed password: $hashedPassword'); // Debug print

        // Check students - match by ID instead of email
        final student = studentsData.firstWhere(
            (s) => s['id'].toString() == id && s['password'] == hashedPassword,
            orElse: () => null);
        if (student != null) {
          return {'type': 'student', 'data': student};
        }

        // Check instructors - match by ID instead of email
        final instructor = instructorsData.firstWhere(
            (i) => i['id'].toString() == id && i['password'] == hashedPassword,
            orElse: () => null);
        if (instructor != null) {
          return {'type': 'instructor', 'data': instructor};
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e'); // Debug print
      throw ConnectionException('Failed to connect to server');
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
