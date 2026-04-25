import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a subject assigned to a professor.
class AssignedSubject {
  final String courseId;
  final String courseName;
  final int semester;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String divisionName;

  AssignedSubject({
    required this.courseId,
    required this.courseName,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.divisionName,
  });

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'courseName': courseName,
        'semester': semester,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'subjectCode': subjectCode,
        'divisionName': divisionName,
      };

  factory AssignedSubject.fromMap(Map<String, dynamic> map) {
    return AssignedSubject(
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      semester: map['semester'] ?? 1,
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      divisionName: map['divisionName'] ?? 'All',
    );
  }
}

/// Model for Professor accounts managed by the admin.
class ProfessorModel {
  final String id;
  final String name;
  final String department;
  final String loginId;
  final String password;
  final List<AssignedSubject> assignedSubjects;
  final DateTime createdAt;

  ProfessorModel({
    required this.id,
    required this.name,
    required this.department,
    required this.loginId,
    required this.password,
    this.assignedSubjects = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'department': department,
        'loginId': loginId,
        'password': password,
        'assignedSubjects': assignedSubjects.map((s) => s.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ProfessorModel.fromMap(String id, Map<String, dynamic> map) {
    return ProfessorModel(
      id: id,
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      loginId: map['loginId'] ?? '',
      password: map['password'] ?? '',
      assignedSubjects: (map['assignedSubjects'] as List? ?? [])
          .map((s) => AssignedSubject.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ProfessorModel copyWith({
    String? name,
    String? department,
    String? loginId,
    String? password,
    List<AssignedSubject>? assignedSubjects,
  }) {
    return ProfessorModel(
      id: id,
      name: name ?? this.name,
      department: department ?? this.department,
      loginId: loginId ?? this.loginId,
      password: password ?? this.password,
      assignedSubjects: assignedSubjects ?? this.assignedSubjects,
      createdAt: createdAt,
    );
  }
}
