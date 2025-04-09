import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../services/config_service.dart';

class AuthService {
  static String hashPassword(String password) {
    final hmac = Hmac(sha256, utf8.encode(ConfigService.hmacKey));
    final digest = hmac.convert(utf8.encode(password));
    return digest.toString();
  }

  static Future<Map<String, dynamic>?> login(String id, String password) async {
    try {
      final studentsResponse =
          await http.get(Uri.parse('${ConfigService.baseUrl}/NFC-Server/data/students.json'));
      final instructorsResponse = await http
          .get(Uri.parse('${ConfigService.baseUrl}/NFC-Server/data/instructors.json'));

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
      if (e.toString().contains('Too many login attempts')) {
        throw ConnectionException('Rate limit exceeded. Please wait 15 minutes.');
      }
      throw ConnectionException('Failed to connect to server');
    }
  }

  // Utility method to fetch courses
  static Future<List<dynamic>> getCourses() async {
    final response = await http.get(Uri.parse('${ConfigService.baseUrl}/courses.json'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['courses'];
    }
    throw Exception('Failed to load courses');
  }

  // Utility method to fetch classes
  static Future<List<dynamic>> getClasses() async {
    final response = await http.get(Uri.parse('${ConfigService.baseUrl}/classes.json'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['classes'];
    }
    throw Exception('Failed to load classes');
  }

  static Future<String> getSecureKey({
    required String sessionToken,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('${ConfigService.baseUrl}/auth/get-key'),
      headers: {
        'Authorization': 'Bearer $sessionToken',
        'X-Device-ID': deviceId,
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('Failed to get secure key');
  }
}

class ConnectionException implements Exception {
  final String message;
  const ConnectionException(this.message);
}
