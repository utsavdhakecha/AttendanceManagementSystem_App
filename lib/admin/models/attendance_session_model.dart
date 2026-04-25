import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single attendance marking session by a professor.
/// This model is stored in Firestore to allow HOD and Admin to see reports.
class AttendanceSessionModel {
  final String id;
  final String professorId;
  final String professorName;
  final String courseId;
  final String courseName;
  final int semester;
  final String subjectId;
  final String subjectName;
  final String date; // yyyy-MM-dd
  final DateTime timestamp;
  final int presentCount;
  final int absentCount;
  final int totalStudents;
  final List<Map<String, dynamic>> studentDetails; // {id, name, roll, status}

  AttendanceSessionModel({
    required this.id,
    required this.professorId,
    required this.professorName,
    required this.courseId,
    required this.courseName,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.date,
    required this.timestamp,
    required this.presentCount,
    required this.absentCount,
    required this.totalStudents,
    required this.studentDetails,
  });

  Map<String, dynamic> toMap() => {
        'professorId': professorId,
        'professorName': professorName,
        'courseId': courseId,
        'courseName': courseName,
        'semester': semester,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'date': date,
        'timestamp': Timestamp.fromDate(timestamp),
        'presentCount': presentCount,
        'absentCount': absentCount,
        'totalStudents': totalStudents,
        'studentDetails': studentDetails,
      };

  factory AttendanceSessionModel.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceSessionModel(
      id: id,
      professorId: map['professorId'] ?? '',
      professorName: map['professorName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      semester: map['semester'] ?? 1,
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      date: map['date'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      presentCount: map['presentCount'] ?? 0,
      absentCount: map['absentCount'] ?? 0,
      totalStudents: map['totalStudents'] ?? 0,
      studentDetails: List<Map<String, dynamic>>.from(map['studentDetails'] ?? []),
    );
  }
}
