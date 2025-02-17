import 'dart:convert';
import 'package:flutter/services.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(
      String identifier, String password) async {
    try {
      final String jsonString =
          await rootBundle.loadString('NFC-Server/data.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      // Check students
      for (var student in data['students']) {
        if (student['id'].toString() == identifier &&
            student['password'] == password) {
          return {
            'type': 'student',
            'data': student,
          };
        }
      }

      // Check instructors
      for (var instructor in data['instructors']) {
        if (instructor['id'].toString() == identifier &&
            instructor['password'] == password) {
          return {
            'type': 'instructor',
            'data': instructor,
          };
        }
      }

      return null; // No match found
    } catch (e) {
      print('Error during authentication: $e');
      return null;
    }
  }
}
