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
        'subject_id': id,
        'subject_name': name,
        'subject_code': subjectCode,
        'course_id': courseId,
        'course_name': courseName,
        'semester': semester,
        'is_elective': isElective ? 1 : 0,
        'elective_group': electiveGroup,
        'academic_year': academicYear,
        'created_at': createdAt.toIso8601String(),
      };

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return SubjectModel(
      id: id,
      name: map['name'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      semester: map['semester'] ?? 1,
      isElective: map['isElective'] ?? false,
      electiveGroup: map['electiveGroup'],
      academicYear: map['academicYear'] ?? '2026',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
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
