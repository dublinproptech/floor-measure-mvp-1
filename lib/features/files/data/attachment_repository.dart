import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'attachment_model.dart';

abstract class AttachmentRepository {
  Stream<List<AttachmentModel>> watchAttachments(String projectId);

  Future<void> upload({
    required String projectId,
    String? roomId,
    String? snagId,
    required AttachmentType type,
    required Uint8List bytes,
  });

  Future<void> delete (AttachmentModel attachment);
}

/// Firestore doc size limit is ~1 MB. Base64 inflates bytes by ~33%, so the
/// raw JPEG must stay under ~740 KB. The controller compresses well below that.

const int kMaxAttachmentBytes = 700 * 1024;

class FirestoreAttachmentRepository implements AttachmentRepository {
  FirestoreAttachmentRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String projectId) =>
      _db.collection('projects').doc(projectId).collection('attachments');

  @override
  Stream<List<AttachmentModel>> watchAttachments(String projectId) =>
      _col(projectId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => AttachmentModel.fromMap(d.id, d.data())).toList());

  @override
  Future<void> upload({
    required String projectId,
    String? roomId,
    String? snagId,
    required AttachmentType type,
    required Uint8List bytes,
  }) async {
    if (bytes.lengthInBytes > kMaxAttachmentBytes) {
      throw Exception('Photo is too large even after compression. Try again.');
    }
    final docRef = _col(projectId).doc();
    await docRef.set(AttachmentModel(
      id: docRef.id,
      projectId: projectId,
      roomId: roomId,
      snagId: snagId,
      type: type,
      imageBase64: base64Encode(bytes),
      createdAt: DateTime.now(),
    ).toMap());
  }

  @override
  Future<void> delete(AttachmentModel a) =>
      _col(a.projectId).doc(a.id).delete();
}
