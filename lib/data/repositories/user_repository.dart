import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Stream<List<UserModel>> watchUsers();
  Future<void> updateUserRole(String userId, UserRole role);
  Future<UserModel> ensureUserDoc({
    required String uid,
    required String email,
    required String name,
  });
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

  @override
  Future<UserModel> ensureUserDoc({
    required String uid,
    required String email,
    required String name,
  }) async {
    final ref = _collection.doc(uid); // keyed by the auth uid — the linchpin
    final snap = await ref.get();
    if (snap.exists) {
      return UserModel.fromFirestore(snap);
    }
    // First login: create the doc at lowest privilege. An admin promotes later.
    final user = UserModel(
      id: uid,
      name: name.isEmpty ? email.split('@').first : name,
      email: email,
      role: UserRole.staff,
    );
    await ref.set(user.toMap());
    return user;
  }
}
