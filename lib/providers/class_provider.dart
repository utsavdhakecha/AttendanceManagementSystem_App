import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/class_model.dart';
import '../models/professor_model.dart';
import 'package:intl/intl.dart';

/// Provider that manages class/course state and CRUD operations.
class ClassProvider with ChangeNotifier {
  List<ClassModel> _classes = [];
  bool _isLoading = false;
  List<String> _todayClassKeys = []; // Stores "ClassName|Subject" for sorting
  List<String> _allowedSubjects = []; // Subjects assigned to the professor

  List<ClassModel> get classes => _classes;
  bool get isLoading => _isLoading;

  /// Load classes assigned to the professor, with priority for classes scheduled for "today".
  /// [todayClassKeys] should be a list of "ClassName|Subject" strings.
  /// [allowedSubjects] should be a list of subject names the professor teaches.
  Future<void> loadClasses({
    List<String>? todayClassKeys,
    List<String>? allowedSubjects,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Update keys if provided, otherwise use existing ones
    if (todayClassKeys != null) {
      _todayClassKeys = todayClassKeys;
    }

    // Update allowed subjects if provided
    if (allowedSubjects != null) {
      _allowedSubjects = allowedSubjects;
    }

    final allData = await DatabaseHelper.instance.getClasses();

    // Filter classes to only show those with subjects assigned to the professor
    List<ClassModel> filteredData = allData;
    if (_allowedSubjects.isNotEmpty) {
      filteredData =
          allData.where((c) => _allowedSubjects.contains(c.subject)).toList();
    }

    // Sort logic: If a class is in today's timetable, it goes to the top.
    if (_todayClassKeys.isNotEmpty) {
      filteredData.sort((a, b) {
        final keyA = '${a.name}|${a.subject}';
        final keyB = '${b.name}|${b.subject}';

        final isAToday = _todayClassKeys.contains(keyA);
        final isBToday = _todayClassKeys.contains(keyB);

        if (isAToday && !isBToday) return -1;
        if (!isAToday && isBToday) return 1;
        return 0; // Maintain original order (created_at DESC) for others
      });
    }

    _classes = filteredData;
    _isLoading = false;
    notifyListeners();
  }

  /// Add a new class and refresh the list.
  Future<void> addClass(ClassModel classModel) async {
    await DatabaseHelper.instance.insertClass(classModel);
    await loadClasses(); // Uses existing _todayClassKeys
  }

  /// Update an existing class and refresh the list.
  Future<void> updateClass(ClassModel classModel) async {
    await DatabaseHelper.instance.updateClass(classModel);
    await loadClasses();
  }

  /// Delete a class by ID and refresh the list.
  Future<void> deleteClass(int id) async {
    await DatabaseHelper.instance.deleteClass(id);
    await loadClasses();
  }

  /// Bulk delete classes and refresh the list.
  Future<void> deleteClasses(List<int> ids) async {
    if (ids.isEmpty) return;
    await DatabaseHelper.instance.deleteClasses(ids);
    await loadClasses();
  }

  /// Sync local database with subjects assigned to the professor in Firestore.
  Future<void> syncWithProfessorAssignments(
      String professorId, String professorName, List<AssignedSubject> assignments) async {
    _isLoading = true;
    notifyListeners();

    final existingClasses = await DatabaseHelper.instance.getClasses();
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    for (final assign in assignments) {
      // Check if this class already exists locally (by Course Name and Subject Name)
      final existingIndex = existingClasses.indexWhere((c) =>
          c.name == assign.courseName && c.subject == assign.subjectName);

      if (existingIndex != -1) {
        // Class exists, but check if metadata is missing
        final existing = existingClasses[existingIndex];
        if (existing.courseId == null || 
            existing.subjectId == null || 
            existing.professorId == null) {
          final updated = existing.copyWith(
            courseId: assign.courseId,
            semester: assign.semester,
            subjectId: assign.subjectId,
            professorId: professorId,
            professorName: professorName,
          );
          await DatabaseHelper.instance.updateClass(updated);
        }
      } else {
        // Create new class
        final newClass = ClassModel(
          name: assign.courseName,
          subject: assign.subjectName,
          createdAt: now,
          courseId: assign.courseId,
          semester: assign.semester,
          subjectId: assign.subjectId,
          professorId: professorId,
          professorName: professorName,
        );
        await DatabaseHelper.instance.insertClass(newClass);
      }
    }

    await loadClasses(); // Reload with new data
  }
}
