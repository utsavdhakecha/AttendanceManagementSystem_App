class AttendanceHistoryModel {
  final String historyId;
  final String attendanceId;
  final String oldStatus;
  final String newStatus;
  final String editedBy;
  final DateTime editedAt;

  AttendanceHistoryModel({
    required this.historyId,
    required this.attendanceId,
    required this.oldStatus,
    required this.newStatus,
    required this.editedBy,
    required this.editedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'history_id': historyId,
      'attendance_id': attendanceId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'edited_by': editedBy,
      'edited_at': editedAt.toIso8601String(),
    };
  }

  factory AttendanceHistoryModel.fromMap(Map<String, dynamic> map) {
    return AttendanceHistoryModel(
      historyId: map['history_id'] as String,
      attendanceId: map['attendance_id'] as String,
      oldStatus: map['old_status'] as String,
      newStatus: map['new_status'] as String,
      editedBy: map['edited_by'] as String,
      editedAt: DateTime.parse(map['edited_at'] as String),
    );
  }
}
