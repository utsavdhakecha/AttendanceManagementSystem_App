/// Unified Student Model for SQLite and Firestore.
class StudentModel {
  final int? id; // SQLite ID
  final String enrollmentNo;
  final String password;
  final String name;
  final int semester;
  final String courseId;
  final String courseName;
  final int electiveConfirmed; // 0 or 1
  final String division;
  final List<String> selectedElectives;
  final DateTime createdAt;

  StudentModel({
    this.id,
    required this.enrollmentNo,
    required this.password,
    required this.name,
    required this.semester,
    required this.courseId,
    required this.courseName,
    this.electiveConfirmed = 0,
    this.division = 'A',
    this.selectedElectives = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'enrollmentNo': enrollmentNo,
      'password': password,
      'name': name,
      'semester': semester,
      'courseId': courseId,
      'courseName': courseName,
      'electiveConfirmed': electiveConfirmed == 1,
      'division': division,
      'selectedElectives': selectedElectives,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// SQLite-specific mapping to match d:/Pro/App/lib/database/database_helper.dart schema
  Map<String, dynamic> toLocalMap() {
    return {
      'enrollment_no': enrollmentNo,
      'password': password,
      'name': name,
      'semester': semester,
      'course_id': courseId,
      'course_name': courseName,
      'elective_confirmed': electiveConfirmed,
      'division': division,
      'created_at': createdAt.toIso8601String(),
      // Selected electives are synced to Firestore primary, 
      // but can be stored as JSON string in SQLite if needed for offline.
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      enrollmentNo: map['enrollment_no'] ?? map['enrollmentNo'] ?? '',
      password: map['password'] ?? '',
      name: map['name'] ?? '',
      semester: map['semester'] ?? 1,
      courseId: map['course_id'] ?? map['courseId'] ?? '',
      courseName: map['course_name'] ?? map['courseName'] ?? '',
      electiveConfirmed: (map['elective_confirmed'] ?? (map['electiveConfirmed'] == true ? 1 : 0)) as int,
      division: map['division'] ?? 'A',
      selectedElectives: List<String>.from(map['selectedElectives'] ?? []),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? 
                 DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? 
                 DateTime.now(),
    );
  }

  StudentModel copyWith({
    String? name,
    String? enrollmentNo,
    String? password,
    String? courseName,
    int? semester,
    int? electiveConfirmed,
    String? division,
    List<String>? selectedElectives,
  }) {
    return StudentModel(
      id: id,
      enrollmentNo: enrollmentNo ?? this.enrollmentNo,
      password: password ?? this.password,
      name: name ?? this.name,
      semester: semester ?? this.semester,
      courseId: courseId,
      courseName: courseName ?? this.courseName,
      electiveConfirmed: electiveConfirmed ?? this.electiveConfirmed,
      division: division ?? this.division,
      selectedElectives: selectedElectives ?? this.selectedElectives,
      createdAt: createdAt,
    );
  }
}
