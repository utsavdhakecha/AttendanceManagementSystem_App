/// Represents a single attendance marking session.
/// Unified model for both SQLite and Firestore synchronization.
class AttendanceSessionModel {
  final String sessionId;
  final String professorId;
  final String professorName;
  final String courseId;
  final String courseName;
  final int semester;
  final String subjectId;
  final String subjectName;
  final String academicYear;
  final String date; // yyyy-MM-dd
  final DateTime timestamp;
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int totalStudents;
  final bool lockedAfter4Hours;
  final String division;
  final List<Map<String, dynamic>> studentDetails;

  AttendanceSessionModel({
    required this.sessionId,
    required this.professorId,
    required this.professorName,
    required this.courseId,
    required this.courseName,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.academicYear,
    required this.date,
    required this.timestamp,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.totalStudents,
    this.lockedAfter4Hours = false,
    this.division = '',
    this.studentDetails = const [],
  });

  Map<String, dynamic> toMap() => {
        'session_id': sessionId,
        'professor_id': professorId,
        'professor_name': professorName,
        'course_id': courseId,
        'course_name': courseName,
        'semester': semester,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'academic_year': academicYear,
        'date': date,
        'timestamp': timestamp.toIso8601String(),
        'present_count': presentCount,
        'absent_count': absentCount,
        'leave_count': leaveCount,
        'total_students': totalStudents,
        'locked_after_4_hours': lockedAfter4Hours ? 1 : 0,
        'division': division,
        'student_details': studentDetails,
      };

  factory AttendanceSessionModel.fromMap(Map<String, dynamic> map) {
    return AttendanceSessionModel(
      sessionId: map['session_id'] ?? map['id'] ?? '',
      professorId: map['professor_id'] ?? map['professorId'] ?? '',
      professorName: map['professor_name'] ?? map['professorName'] ?? '',
      courseId: map['course_id'] ?? map['courseId'] ?? '',
      courseName: map['course_name'] ?? map['courseName'] ?? '',
      semester: map['semester'] ?? 1,
      subjectId: map['subject_id'] ?? map['subjectId'] ?? '',
      subjectName: map['subject_name'] ?? map['subjectName'] ?? '',
      academicYear: map['academic_year'] ?? map['academicYear'] ?? '2026',
      date: map['date'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      presentCount: map['present_count'] ?? map['presentCount'] ?? 0,
      absentCount: map['absent_count'] ?? map['absentCount'] ?? 0,
      leaveCount: map['leave_count'] ?? map['leaveCount'] ?? 0,
      totalStudents: map['total_students'] ?? map['totalStudents'] ?? 0,
      lockedAfter4Hours: (map['locked_after_4_hours'] ?? 0) == 1 ||
          (map['lockedAfter4Hours'] ?? false) == true,
      division: map['division'] ?? '',
      studentDetails: List<Map<String, dynamic>>.from(
          map['student_details'] ?? map['studentDetails'] ?? []),
    );
  }

  AttendanceSessionModel copyWith({
    DateTime? timestamp,
    int? presentCount,
    int? absentCount,
    int? leaveCount,
    bool? lockedAfter4Hours,
    List<Map<String, dynamic>>? studentDetails,
  }) {
    return AttendanceSessionModel(
      sessionId: sessionId,
      professorId: professorId,
      professorName: professorName,
      courseId: courseId,
      courseName: courseName,
      semester: semester,
      subjectId: subjectId,
      subjectName: subjectName,
      academicYear: academicYear,
      date: date,
      timestamp: timestamp ?? this.timestamp,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      leaveCount: leaveCount ?? this.leaveCount,
      totalStudents: totalStudents,
      lockedAfter4Hours: lockedAfter4Hours ?? this.lockedAfter4Hours,
      division: division,
      studentDetails: studentDetails ?? this.studentDetails,
    );
  }
}
