/// Model representing a single timetable entry.
class TimetableModel {
  final int? id; // Legacy local ID (keep for backward compatibility if needed)
  final String? docId; // Firestore specific ID
  final String day; // Monday, Tuesday, etc.
  final String startTime; // 24-hour format (e.g., "10:00")
  final String endTime; // 24-hour format (e.g., "11:00")
  final String className; // Name of the class/section
  final String subject; // Specific subject matter

  final String? professorId; // ID of the professor

  TimetableModel({
    this.id,
    this.docId,
    this.professorId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.className,
    required this.subject,
  });

  /// Convert to a Map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doc_id': docId,
      'professor_id': professorId,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
      'class_name': className,
      'subject': subject,
    };
  }

  /// Create from a database Map.
  factory TimetableModel.fromMap(Map<String, dynamic> map, {String? firestoreDocId}) {
    return TimetableModel(
      id: map['id'] as int?,
      docId: firestoreDocId ?? map['doc_id'] as String?,
      professorId: map['professor_id'] as String?,
      day: map['day'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      className: map['class_name'] as String,
      subject: map['subject'] as String,
    );
  }

  TimetableModel copyWith({
    int? id,
    String? docId,
    String? professorId,
    String? day,
    String? startTime,
    String? endTime,
    String? className,
    String? subject,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      professorId: professorId ?? this.professorId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      className: className ?? this.className,
      subject: subject ?? this.subject,
    );
  }
}
