import 'package:cloud_firestore/cloud_firestore.dart';
import 'snag_model.dart';

abstract class SnagRepository {
  Stream<List<SnagModel>> watchSnags(String projectId);
  Future<void> addSnag(SnagModel snag);
  Future<void> updateSnag(SnagModel snag);
  Future<void> updateStatus(String projectId, String snagId, SnagStatus status);
  Future<void> assign(String projectId, String snagId, String userId);
  Future<void> deleteSnag(String projectId, String snagId);

  /// Generates the next sequential ref, e.g. "SNAG-001", "SNAG-002".
  Future<String> nextRef(String projectId);
  /// All snags across every project — used only by the Dashboard for counts.
  Stream<List<SnagModel>> watchAllSnags();
}

class FirestoreSnagRepository implements SnagRepository {
  FirestoreSnagRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String projectId) =>
      _firestore.collection('projects').doc(projectId).collection('snags');

  @override
  Stream<List<SnagModel>> watchSnags(String projectId) {
    return _collection(projectId).orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(SnagModel.fromFirestore).toList(),
        );
  }

  @override
  Future<void> addSnag(SnagModel snag) async {
    await _collection(snag.projectId).add(snag.toMap());
  }

  @override
  Future<void> updateSnag(SnagModel snag) async {
    if (snag.id.isEmpty) {
      throw ArgumentError('Cannot update a SnagModel with an empty id');
    }
    await _collection(snag.projectId).doc(snag.id).update(snag.toMap());
  }

  @override
  Future<void> updateStatus(String projectId, String snagId, SnagStatus status) async {
    await _collection(projectId).doc(snagId).update({'status': status.name});
  }

  @override
  Future<void> assign(String projectId, String snagId, String userId) async {
    await _collection(projectId).doc(snagId).update({'assignedTo': userId});
  }

  @override
  Future<void> deleteSnag(String projectId, String snagId) async {
    await _collection(projectId).doc(snagId).delete();
  }

  @override
  Future<String> nextRef(String projectId) async {
    final snap = await _collection(projectId).count().get();
    final next = (snap.count ?? 0) + 1;
    return 'SNAG-${next.toString().padLeft(3, '0')}';
  }

  @override
  Stream<List<SnagModel>> watchAllSnags() {
    return _firestore.collectionGroup('snags').snapshots().map(
          (snap) => snap.docs.map(SnagModel.fromFirestore).toList(),
        );
  }
}
