/// Predefined course model with fixed semesters.
class CourseModel {
  final String id;
  final String name;
  final int totalSemesters;

  const CourseModel({
    required this.id,
    required this.name,
    required this.totalSemesters,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'totalSemesters': totalSemesters,
      };

  factory CourseModel.fromMap(String id, Map<String, dynamic> map) {
    return CourseModel(
      id: id,
      name: map['name'] ?? '',
      totalSemesters: map['totalSemesters'] ?? 0,
    );
  }

  /// Predefined CSE courses.
  static const List<CourseModel> predefined = [
    CourseModel(id: 'BTECH_CSE', name: 'B.Tech Computer Science', totalSemesters: 8),
    CourseModel(id: 'BCA', name: 'BCA (Computer Applications)', totalSemesters: 6),
    CourseModel(id: 'MCA', name: 'MCA (Computer Applications)', totalSemesters: 4),
    CourseModel(id: 'MTECH_CSE', name: 'M.Tech Computer Science', totalSemesters: 4),
    CourseModel(id: 'BSC_CS', name: 'B.Sc Computer Science', totalSemesters: 6),
    CourseModel(id: 'MSC_CS', name: 'M.Sc Computer Science', totalSemesters: 4),
    CourseModel(id: 'BTECH_IT', name: 'B.Tech Information Technology', totalSemesters: 8),
  ];
}
