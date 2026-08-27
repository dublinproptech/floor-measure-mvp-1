import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/project_model.dart';
import '../data/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
      (ref) => FirestoreProjectRepository(ref.watch(firestoreProvider)),
);

final projectListProvider = StreamProvider.autoDispose<List<ProjectModel>>(
      (ref) => ref.watch(projectRepositoryProvider).watchProjects(),
);

final projectProvider =
StreamProvider.autoDispose.family<ProjectModel?, String>(
      (ref, id) => ref.watch(projectRepositoryProvider).watchProject(id),
);

final projectControllerProvider =
AsyncNotifierProvider.autoDispose<ProjectController, void>(ProjectController.new);

class ProjectController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  Future<String?> create(ProjectModel p) async {
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async { id = await _repo.addProject(p); });
    return state.hasError ? null : id;
  }

  Future<bool> updateProject(ProjectModel p) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateProject(p));
    return !state.hasError;
  }

  Future<void> updateStatus(String id, ProjectStatus status) async {
    state = await AsyncValue.guard(() => _repo.updateStatus(id, status));
  }

  Future<void> delete(String id) async {
    state = await AsyncValue.guard(() => _repo.deleteProject(id));
  }
}