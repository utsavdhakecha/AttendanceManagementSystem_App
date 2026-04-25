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

  /// Predefined list of courses.
  static const List<CourseModel> predefined = [
    CourseModel(id: 'bca', name: 'BCA', totalSemesters: 6),
    CourseModel(id: 'mca', name: 'MCA', totalSemesters: 4),
    CourseModel(id: 'btech', name: 'B.Tech', totalSemesters: 8),
    CourseModel(id: 'mtech', name: 'M.Tech', totalSemesters: 4),
    CourseModel(id: 'bba', name: 'BBA', totalSemesters: 6),
    CourseModel(id: 'mba', name: 'MBA', totalSemesters: 4),
    CourseModel(id: 'bcom', name: 'B.Com', totalSemesters: 6),
    CourseModel(id: 'mcom', name: 'M.Com', totalSemesters: 4),
    CourseModel(id: 'bsc', name: 'BSc', totalSemesters: 6),
    CourseModel(id: 'msc', name: 'MSc', totalSemesters: 4),
  ];
}
