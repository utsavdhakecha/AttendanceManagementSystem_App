import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for HOD accounts managed by the admin.
class HodModel {
  final String id;
  final String name;
  final String department;
  final String loginId;
  final String password;
  final DateTime createdAt;

  HodModel({
    required this.id,
    required this.name,
    required this.department,
    required this.loginId,
    required this.password,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'department': department,
        'loginId': loginId,
        'password': password,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory HodModel.fromMap(String id, Map<String, dynamic> map) {
    return HodModel(
      id: id,
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      loginId: map['loginId'] ?? '',
      password: map['password'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  HodModel copyWith({
    String? name,
    String? department,
    String? loginId,
    String? password,
  }) {
    return HodModel(
      id: id,
      name: name ?? this.name,
      department: department ?? this.department,
      loginId: loginId ?? this.loginId,
      password: password ?? this.password,
      createdAt: createdAt,
    );
  }
}
