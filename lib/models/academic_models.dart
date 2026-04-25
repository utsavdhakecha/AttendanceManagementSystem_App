class CourseModel {
  final String courseId;
  final String courseName;
  final int totalSemesters;

  CourseModel({
    required this.courseId,
    required this.courseName,
    required this.totalSemesters,
  });

  Map<String, dynamic> toMap() {
    return {
      'course_id': courseId,
      'course_name': courseName,
      'total_semesters': totalSemesters,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      courseId: map['course_id'] as String,
      courseName: map['course_name'] as String,
      totalSemesters: map['total_semesters'] as int,
    );
  }
}

class SubjectModel {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int semester;
  final String courseId;
  final bool isElective;
  final String academicYear;

  SubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.semester,
    required this.courseId,
    this.isElective = false,
    required this.academicYear,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'semester': semester,
      'course_id': courseId,
      'is_elective': isElective ? 1 : 0,
      'academic_year': academicYear,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      subjectId: map['subject_id'] as String,
      subjectName: map['subject_name'] as String,
      subjectCode: map['subject_code'] as String,
      semester: map['semester'] as int,
      courseId: map['course_id'] as String,
      isElective: (map['is_elective'] as int) == 1,
      academicYear: map['academic_year'] as String,
    );
  }
}
