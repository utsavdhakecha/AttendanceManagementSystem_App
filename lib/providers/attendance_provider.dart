import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../models/class_model.dart';
import '../models/attendance_session_model.dart';
import '../admin/services/firestore_service.dart';

/// Provider that manages attendance marking, history, and report generation.
class AttendanceProvider with ChangeNotifier {
  Map<String, String> _attendanceMap = {};
  List<AttendanceModel> _attendanceHistory = [];
  bool _isLoading = false;
  AttendanceSessionModel? _currentSession;
  bool _isSessionSaved = false;

  static const int lockWindowMinutes = 360;

  Map<String, String> get attendanceMap => _attendanceMap;
  List<AttendanceModel> get attendanceHistory => _attendanceHistory;
  bool get isLoading => _isLoading;
  AttendanceSessionModel? get currentSession => _currentSession;
  bool get isSessionSaved => _isSessionSaved;

  bool get isLocked {
    if (_currentSession == null) return false;

    if (!_isSessionSaved) {
      // New unsaved session. Only allow if the selected date is today.
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      if (_currentSession!.date.compareTo(todayStr) != 0) return true;
      return false;
    }

    if (_currentSession!.lockedAfter4Hours) return true;
    final now = DateTime.now();
    final difference = now.difference(_currentSession!.timestamp);
    return difference.inMinutes >= lockWindowMinutes;
  }

  Duration get timeRemaining {
    if (_currentSession == null || !_isSessionSaved) return Duration.zero;
    if (_currentSession!.lockedAfter4Hours) return Duration.zero;
    final lockTime = _currentSession!.timestamp
        .add(const Duration(minutes: lockWindowMinutes));
    final remaining = lockTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Load attendance by classId and date, using ClassModel for real metadata
  Future<void> loadAttendance(
      int classId, String date, List<StudentModel> students,
      {ClassModel? classModel}) async {
    _isLoading = true;
    notifyListeners();

    final sessionId = "${classId}_$date";
    final records =
        await DatabaseHelper.instance.getAttendanceBySession(sessionId);

    _attendanceMap = {};
    for (final record in records) {
      _attendanceMap[record.studentId] = record.status;
    }

    for (final student in students) {
      if (!_attendanceMap.containsKey(student.enrollmentNo)) {
        _attendanceMap[student.enrollmentNo] = 'present';
      }
    }

    // Check for approved leaves
    final approvedLeaves =
        await DatabaseHelper.instance.getApprovedLeavesForDate(date);
    for (final leave in approvedLeaves) {
      if (_attendanceMap.containsKey(leave.studentId)) {
        _attendanceMap[leave.studentId] = 'on leave';
      }
    }

    final savedSession = await DatabaseHelper.instance.getSession(sessionId);
    if (savedSession != null) {
      _currentSession = savedSession;
      _isSessionSaved = true;
    } else {
      _isSessionSaved = false;
      _currentSession = AttendanceSessionModel(
        sessionId: sessionId,
        subjectId: classModel?.subjectId ?? 'unknown',
        subjectName: classModel?.subject ?? 'Unknown Subject',
        professorId: classModel?.professorId ?? 'unknown',
        professorName: classModel?.professorName ?? 'Unknown',
        academicYear: '2025-26',
        courseId: classModel?.courseId ?? 'unknown',
        courseName: classModel?.courseName ?? 'Unknown Course',
        semester: classModel?.semester ?? 1,
        division: classModel?.divisionName ?? '',
        date: date,
        timestamp: DateTime.now(),
        presentCount: 0,
        absentCount: 0,
        leaveCount: 0,
        totalStudents: students.length,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleStatus(String enrollmentNo) {
    if (isLocked) return;
    if (_attendanceMap[enrollmentNo] == 'on leave') return;

    _attendanceMap[enrollmentNo] =
        (_attendanceMap[enrollmentNo] == 'present') ? 'absent' : 'present';
    notifyListeners();
  }

  void markAllPresent(List<StudentModel> students) {
    if (isLocked) return;
    for (final student in students) {
      if (_attendanceMap[student.enrollmentNo] != 'on leave') {
        _attendanceMap[student.enrollmentNo] = 'present';
      }
    }
    notifyListeners();
  }

  void markAllAbsent(List<StudentModel> students) {
    if (isLocked) return;
    for (final student in students) {
      if (_attendanceMap[student.enrollmentNo] != 'on leave') {
        _attendanceMap[student.enrollmentNo] = 'absent';
      }
    }
    notifyListeners();
  }

  Future<void> saveAttendance(
      ClassModel classModel, String date, List<StudentModel> students) async {
    if (_currentSession == null) return;

    int presentCount = 0;
    int absentCount = 0;
    int leaveCount = 0;
    final List<Map<String, dynamic>> studentDetails = [];
    final List<AttendanceModel> attendancesToSave = [];

    for (final student in students) {
      final status = _attendanceMap[student.enrollmentNo] ?? 'present';
      if (status == 'present') {
        presentCount++;
      } else if (status == 'absent') {
        absentCount++;
      } else if (status == 'on leave') {
        leaveCount++;
      }

      studentDetails.add({
        'id': student.id.toString(),
        'name': student.name,
        'enrollmentNo': student.enrollmentNo,
        'status': status,
      });

      attendancesToSave.add(AttendanceModel(
        sessionId: _currentSession!.sessionId,
        studentId: student.enrollmentNo,
        status: status,
      ));
    }

    await DatabaseHelper.instance.upsertAttendanceBatch(attendancesToSave);

    final updatedSession = _currentSession!.copyWith(
      presentCount: presentCount,
      absentCount: absentCount,
      leaveCount: leaveCount,
      studentDetails: studentDetails,
      timestamp: _isSessionSaved
          ? _currentSession!.timestamp
          : DateTime
              .now(), // Preserve exact initial saving time to lock strictly from first save
    );
    await DatabaseHelper.instance.insertSession(updatedSession);

    _currentSession = updatedSession;
    _isSessionSaved = true;

    // Fire and forget Firestore save for better UI performance
    FirestoreService().saveAttendanceSession(updatedSession).catchError((e) {
      debugPrint("Firestore sync error: $e");
    });

    notifyListeners();
  }

  Future<void> loadAttendanceHistory(int classId) async {
    _isLoading = true;
    notifyListeners();
    _attendanceHistory =
        await DatabaseHelper.instance.getAttendanceByClass(classId);
    _isLoading = false;
    notifyListeners();
  }

  Future<double> getAttendancePercentage(
      String enrollmentNo, dynamic id) async {
    final present =
        await DatabaseHelper.instance.getPresentCountForClass(enrollmentNo, id);
    final onLeave =
        await DatabaseHelper.instance.getOnLeaveCountForClass(enrollmentNo, id);
    final total =
        await DatabaseHelper.instance.getTotalDaysForStudent(enrollmentNo, id);
    final effectiveTotal = total - onLeave;
    return (effectiveTotal > 0) ? (present / effectiveTotal) * 100 : 0.0;
  }

  Future<List<List<String>>> generateCsvData(
      int classId, List<StudentModel> students) async {
    final List<List<String>> csvData = [
      ['Enrollment No', 'Name', 'Present', 'Absent', 'Total', 'Percentage']
    ];
    for (final student in students) {
      final present = await DatabaseHelper.instance
          .getPresentCountForClass(student.enrollmentNo, classId);
      final onLeave = await DatabaseHelper.instance
          .getOnLeaveCountForClass(student.enrollmentNo, classId);
      final total = await DatabaseHelper.instance
          .getTotalDaysForStudent(student.enrollmentNo, classId);
      final effectiveTotal = total - onLeave;
      final absent = effectiveTotal - present;
      final percentage =
          effectiveTotal > 0 ? ((present / effectiveTotal) * 100) : 0.0;
      csvData.add([
        student.enrollmentNo,
        student.name,
        present.toString(),
        absent.toString(),
        total.toString(),
        '${percentage.toStringAsFixed(1)}%'
      ]);
    }
    return csvData;
  }
}
