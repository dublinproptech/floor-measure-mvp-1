import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_model.dart';

abstract class ProjectRepository {
  Stream<List<ProjectModel>> watchProjects();
  Stream<ProjectModel?> watchProject(String id);
  Future<String> addProject(ProjectModel project);
  Future<void> updateProject(ProjectModel project);
  Future<void> updateStatus(String id, ProjectStatus status);
  Future<void> deleteProject(String id);
}

class FirestoreProjectRepository implements ProjectRepository {
  FirestoreProjectRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('projects');

  @override
  Stream<List<ProjectModel>> watchProjects() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ProjectModel.fromMap(d.id, d.data())).toList());

  @override
  Stream<ProjectModel?> watchProject(String id) => _col.doc(id).snapshots().map(
          (d) => d.exists ? ProjectModel.fromMap(d.id, d.data()!) : null);

  @override
  Future<String> addProject(ProjectModel p) async => (await _col.add(p.toMap())).id;

  @override
  Future<void> updateProject(ProjectModel p) => _col.doc(p.id).update(p.toMap());

  @override
  Future<void> updateStatus(String id, ProjectStatus status) =>
      _col.doc(id).update({'status': status.name});

  @override
  Future<void> deleteProject(String id) => _col.doc(id).delete();
}