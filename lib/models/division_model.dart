class DivisionModel {
  final String id;
  final String name;
  final String courseId;
  final int semester;

  DivisionModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.semester,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'courseId': courseId,
        'semester': semester,
      };

  factory DivisionModel.fromMap(String id, Map<String, dynamic> map) {
    return DivisionModel(
      id: id,
      name: map['name'] ?? '',
      courseId: map['courseId'] ?? '',
      semester: map['semester'] ?? 1,
    );
  }
}
