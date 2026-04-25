/// Model for subjects assigned to a course and semester.
class SubjectModel {
  final String id;
  final String name;
  final String subjectCode;
  final String courseId;
  final String courseName;
  final int semester;
  final bool isElective;
  final String? electiveGroup; 
  final String academicYear;
  final DateTime createdAt;

  SubjectModel({
    required this.id,
    required this.name,
    required this.subjectCode,
    required this.courseId,
    required this.courseName,
    required this.semester,
    required this.isElective,
    this.electiveGroup,
    required this.academicYear,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'subjectCode': subjectCode,
        'courseId': courseId,
        'courseName': courseName,
        'semester': semester,
        'isElective': isElective,
        'electiveGroup': electiveGroup,
        'academicYear': academicYear,
        'createdAt': createdAt.toIso8601String(),
      };

  /// SQLite-specific mapping to match d:/Pro/App/lib/database/database_helper.dart schema
  Map<String, dynamic> toLocalMap() => {
        'subject_id': id,
        'subject_name': name,
        'subject_code': subjectCode,
        'semester': semester,
        'course_id': courseId,
        'is_elective': isElective ? 1 : 0,
        'elective_group': electiveGroup,
        'academic_year': academicYear,
      };

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return SubjectModel(
      id: id,
      name: map['name'] ?? map['subject_name'] ?? '',
      subjectCode: map['subjectCode'] ?? map['subject_code'] ?? '',
      courseId: map['courseId'] ?? map['course_id'] ?? '',
      courseName: map['courseName'] ?? map['course_name'] ?? '',
      semester: map['semester'] ?? 1,
      isElective: map['isElective'] ?? (map['is_elective'] == 1) ?? false,
      electiveGroup: map['electiveGroup'] ?? map['elective_group'],
      academicYear: map['academicYear'] ?? map['academic_year'] ?? '2026',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? 
                 DateTime.tryParse(map['created_at']?.toString() ?? '') ?? 
                 DateTime.now(),
    );
  }

  factory SubjectModel.fromLocalMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['subject_id'] ?? '',
      name: map['subject_name'] ?? '',
      subjectCode: map['subject_code'] ?? '',
      courseId: map['course_id'] ?? '',
      courseName: map['course_name'] ?? 'Computer Science Engineering',
      semester: map['semester'] ?? 1,
      isElective: (map['is_elective'] ?? 0) == 1,
      electiveGroup: map['elective_group'],
      academicYear: map['academic_year'] ?? '2026',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
