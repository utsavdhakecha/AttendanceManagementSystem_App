import 'package:flutter/material.dart';
import '../admin/services/firestore_service.dart';
import '../models/student_model.dart';

/// Provider that manages student state, scoped to a specific class/semester.
class StudentProvider with ChangeNotifier {
  List<StudentModel> _students = [];
  bool _isLoading = false;

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;

  // Stubs for orphaned legacy UI to prevent compiler errors.
  Future<void> addStudent(StudentModel student) async {}
  Future<void> updateStudent(StudentModel student) async {}
  Future<void> deleteStudents(List<int> ids, int classId) async {}
  Future<void> deleteStudent(int id, int classId) async {}

  /// Sync local student list with the predefined database in Firestore based on exact assignment details.
  /// Bypasses local SQLite entirely to ensure we never show stale or incorrectly grouped students.
  Future<void> syncFirestoreStudents({
    required int classId,
    required String courseId,
    required int semester,
    required String divisionName,
    required String subjectId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fsService = FirestoreService();

      // Fetch precise list straight from cloud.
      final fireStudents = await fsService.getStudentsForAssignment(
        courseId: courseId,
        semester: semester,
        divisionName: divisionName,
        subjectId: subjectId,
      );

      // Directly apply as source of truth.
      _students = fireStudents;
      _isLoading = false;
      notifyListeners();

    } catch (e) {
      debugPrint('Firestore fetch failed: $e');
      _students = [];
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
