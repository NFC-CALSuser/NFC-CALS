import 'dart:convert';
import 'package:flutter/services.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(String id, String password) async {
    try {
      // Read the JSON file
      final String jsonString =
          await rootBundle.loadString('NFC-Server/data.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      // Check admin credentials
      if (id == 'admin1' && password == 'admin1') {
        // Updated credentials
        return {
          'type': 'admin',
          'data': {'name': 'Admin', 'id': 'admin1'}
        };
      }

      // Check students
      final students = data['students'] as List;
      for (var student in students) {
        if (student['id'].toString() == id && student['password'] == password) {
          return {
            'type': 'student',
            'data': student,
          };
        }
      }

      // Check instructors
      final instructors = data['instructors'] as List;
      for (var instructor in instructors) {
        if (instructor['id'] == id && instructor['password'] == password) {
          return {
            'type': 'instructor',
            'data': instructor,
          };
        }
      }

      return null; // Return null if no matching credentials found
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }
}
