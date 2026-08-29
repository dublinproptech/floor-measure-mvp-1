import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Stream<List<UserModel>> watchUsers();
  Future<void> updateUserRole(String userId, UserRole role);
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  @override
  Stream<List<UserModel>> watchUsers() {
    return _collection.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(UserModel.fromFirestore).toList(),
        );
  }

  @override
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _collection.doc(userId).update({'role': role.name});
  }
}
