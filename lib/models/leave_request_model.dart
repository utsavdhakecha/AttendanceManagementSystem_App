class LeaveRequestModel {
  final int? id;
  final String studentId; // Enrollment No
  final String studentName;
  final String fromDate; // ISO format
  final String toDate; // ISO format
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String appliedAt; // ISO format

  LeaveRequestModel({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = 'pending',
    required this.appliedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'from_date': fromDate,
      'to_date': toDate,
      'reason': reason,
      'status': status,
      'applied_at': appliedAt,
    };
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    return LeaveRequestModel(
      id: map['id'],
      studentId: map['student_id'],
      studentName: map['student_name'],
      fromDate: map['from_date'],
      toDate: map['to_date'],
      reason: map['reason'],
      status: map['status'] ?? 'pending',
      appliedAt: map['applied_at'],
    );
  }

  LeaveRequestModel copyWith({
    int? id,
    String? studentId,
    String? studentName,
    String? fromDate,
    String? toDate,
    String? reason,
    String? status,
    String? appliedAt,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
