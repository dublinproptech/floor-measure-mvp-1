import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_model.dart';

abstract class RoomRepository {
  Stream<List<RoomModel>> watchRooms(String projectId);
  Future<void> addRoom(RoomModel room);
  Future<void> updateRoom(RoomModel room);
  Future<void> deleteRoom(String projectId, String roomId);
}

class FirestoreRoomRepository implements RoomRepository {
  FirestoreRoomRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String projectId) =>
      _db.collection('projects').doc(projectId).collection('rooms');

  @override
  Stream<List<RoomModel>> watchRooms(String projectId) => _col(projectId)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => RoomModel.fromMap(d.id, d.data())).toList());

  @override
  Future<void> addRoom(RoomModel r) => _col(r.projectId).add(r.toMap());

  @override
  Future<void> updateRoom(RoomModel r) =>
      _col(r.projectId).doc(r.id).update(r.toMap());

  @override
  Future<void> deleteRoom(String projectId, String roomId) =>
      _col(projectId).doc(roomId).delete();
}