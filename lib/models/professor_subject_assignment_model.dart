class ProfessorSubjectAssignmentModel {
  final String assignmentId;
  final String professorId;
  final String subjectId;
  final String academicYear;
  final int semester;
  final bool active;

  ProfessorSubjectAssignmentModel({
    required this.assignmentId,
    required this.professorId,
    required this.subjectId,
    required this.academicYear,
    required this.semester,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'assignment_id': assignmentId,
      'professor_id': professorId,
      'subject_id': subjectId,
      'academic_year': academicYear,
      'semester': semester,
      'active': active ? 1 : 0,
    };
  }

  factory ProfessorSubjectAssignmentModel.fromMap(Map<String, dynamic> map) {
    return ProfessorSubjectAssignmentModel(
      assignmentId: map['assignment_id'] as String,
      professorId: map['professor_id'] as String,
      subjectId: map['subject_id'] as String,
      academicYear: map['academic_year'] as String,
      semester: map['semester'] as int,
      active: (map['active'] as int) == 1,
    );
  }
}
