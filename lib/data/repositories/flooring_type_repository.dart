import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flooring_type_model.dart';

abstract class FlooringTypeRepository {
  Stream<List<FlooringTypeModel>> watchFlooringTypes();
  Future<void> addFlooringType(FlooringTypeModel type);
  Future<void> updateFlooringType(FlooringTypeModel type);
  Future<void> deleteFlooringType(String id);
}

class FirestoreFlooringTypeRepository implements FlooringTypeRepository {
  FirestoreFlooringTypeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('flooringTypes');

  @override
  Stream<List<FlooringTypeModel>> watchFlooringTypes() {
    return _collection.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(FlooringTypeModel.fromFirestore).toList(),
        );
  }

  @override
  Future<void> addFlooringType(FlooringTypeModel type) async {
    await _collection.add(type.toMap());
  }

  @override
  Future<void> updateFlooringType(FlooringTypeModel type) async {
    if (type.id.isEmpty) {
      throw ArgumentError('Cannot update a FlooringTypeModel with an empty id');
    }
    await _collection.doc(type.id).update(type.toMap());
  }

  @override
  Future<void> deleteFlooringType(String id) async {
    await _collection.doc(id).delete();
  }
}
