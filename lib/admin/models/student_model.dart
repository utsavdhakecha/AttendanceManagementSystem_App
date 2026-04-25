import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for predefined student accounts.
/// Students log in with enrollment number and password.
class StudentModel {
  final String id;
  final String enrollmentNo;
  final String name;
  final String password;
  final String courseId;
  final String courseName;
  final int semester;
  final Map<String, String> selectedElectives; // { "Group A": subjectId, ... }
  final bool electiveConfirmed;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.enrollmentNo,
    required this.name,
    required this.password,
    required this.courseId,
    required this.courseName,
    required this.semester,
    Map<String, String>? selectedElectives,
    this.electiveConfirmed = false,
    DateTime? createdAt,
  })  : selectedElectives = selectedElectives ?? {},
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'enrollmentNo': enrollmentNo,
        'name': name,
        'password': password,
        'courseId': courseId,
        'courseName': courseName,
        'semester': semester,
        'selectedElectives': selectedElectives,
        'electiveConfirmed': electiveConfirmed,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    return StudentModel(
      id: id,
      enrollmentNo: map['enrollmentNo'] ?? '',
      name: map['name'] ?? '',
      password: map['password'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      semester: map['semester'] ?? 1,
      selectedElectives: Map<String, String>.from(map['selectedElectives'] ?? {}),
      electiveConfirmed: map['electiveConfirmed'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  StudentModel copyWith({
    String? enrollmentNo,
    String? name,
    String? password,
    String? courseId,
    String? courseName,
    int? semester,
    Map<String, String>? selectedElectives,
    bool? electiveConfirmed,
  }) {
    return StudentModel(
      id: id,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      name: name ?? this.name,
      password: password ?? this.password,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      semester: semester ?? this.semester,
      selectedElectives: selectedElectives ?? this.selectedElectives,
      electiveConfirmed: electiveConfirmed ?? this.electiveConfirmed,
      createdAt: createdAt,
    );
  }
}
