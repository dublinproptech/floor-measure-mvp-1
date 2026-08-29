import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { admin, surveyor, projectManager, staff }

UserRole userRoleFromString(String value) => UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.staff,
    );

/// Firestore collection: users/{id}
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: userRoleFromString(map['role'] as String? ?? 'staff'),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('UserModel.fromFirestore: doc ${doc.id} has no data');
    }
    return UserModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.name,
      };

  @override
  List<Object?> get props => [id, name, email, role];
}
