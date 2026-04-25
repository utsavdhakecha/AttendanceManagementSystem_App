/// Model representing a single student's attendance for a specific session.
class AttendanceModel {
  final int? id;
  final String sessionId;
  final String studentId;
  final String status; // 'present', 'absent', etc.

  AttendanceModel({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
  });

  /// Convert to a Map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'status': status,
    };
  }

  /// Create from a database Map.
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      status: map['status'] as String,
    );
  }

  AttendanceModel copyWith({
    int? id,
    String? sessionId,
    String? studentId,
    String? status,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
    );
  }
}
