import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings_model.dart';

abstract class SettingsRepository {
  Stream<AppSettingsModel> watchSettings();
  Future<void> updateSettings(AppSettingsModel settings);
}

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('settings').doc(AppSettingsModel.docId);

  @override
  Stream<AppSettingsModel> watchSettings() {
    return _doc.snapshots().map(AppSettingsModel.fromFirestore);
  }

  @override
  Future<void> updateSettings(AppSettingsModel settings) async {
    // merge: true so partial writes never wipe fields not included yet.
    await _doc.set(settings.toMap(), SetOptions(merge: true));
  }
}
