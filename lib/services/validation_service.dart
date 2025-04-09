class ValidationService {
  static bool isValidStudentId(String id) {
    return RegExp(r'^\d{9}$').hasMatch(id);
  }

  static bool isValidCourseId(String courseId) {
    return RegExp(r'^[A-Z]{3,4}\d{3}$').hasMatch(courseId);
  }

  static bool isValidClassroom(String classroom) {
    return RegExp(r'^[A-Z]-\d{3}$').hasMatch(classroom);
  }

  static String? sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input.replaceAll(RegExp(r'[<>&"/]'), '');
  }
}