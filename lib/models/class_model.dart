class ClassModel {
  final int? id;
  final String name; 
  final String subject;
  final String createdAt;
  
  // Firestore metadata for sync
  final String? courseId;
  final int? semester;
  final String? subjectId;
  final String? professorId;
  final String? professorName;
  final String? courseName;

  final String? divisionName;

  ClassModel({
    this.id,
    required this.name,
    required this.subject,
    required this.createdAt,
    this.courseId,
    this.semester,
    this.subjectId,
    this.professorId,
    this.professorName,
    this.courseName,
    this.divisionName,
  });

  /// Convert a ClassModel to a Map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'created_at': createdAt,
      'course_id': courseId,
      'semester': semester,
      'subject_id': subjectId,
      'professor_id': professorId,
      'professor_name': professorName,
      'course_name': courseName,
      'division_name': divisionName,
    };
  }

  /// Create a ClassModel from a database Map.
  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      subject: map['subject'] as String,
      createdAt: map['created_at'] as String,
      courseId: map['course_id'] as String?,
      semester: map['semester'] as int?,
      subjectId: map['subject_id'] as String?,
      professorId: map['professor_id'] as String?,
      professorName: map['professor_name'] as String?,
      courseName: map['course_name'] as String?,
      divisionName: map['division_name'] as String?,
    );
  }

  /// Create a copy with updated fields.
  ClassModel copyWith({
    int? id,
    String? name,
    String? subject,
    String? createdAt,
    String? courseId,
    int? semester,
    String? subjectId,
    String? professorId,
    String? professorName,
    String? courseName,
    String? divisionName,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      courseId: courseId ?? this.courseId,
      semester: semester ?? this.semester,
      subjectId: subjectId ?? this.subjectId,
      professorId: professorId ?? this.professorId,
      professorName: professorName ?? this.professorName,
      courseName: courseName ?? this.courseName,
      divisionName: divisionName ?? this.divisionName,
    );
  }
}
