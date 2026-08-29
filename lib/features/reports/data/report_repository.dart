import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_model.dart';

abstract class ReportRepository {
  Future<void> recordReport(ReportModel report);
}

class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(this._db);
  final FirebaseFirestore _db;

  @override
  Future<void> recordReport(ReportModel r) => _db
      .collection('projects')
      .doc(r.projectId)
      .collection('reports')
      .add(r.toMap());
}