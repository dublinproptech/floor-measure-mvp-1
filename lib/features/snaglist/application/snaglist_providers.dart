import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/application/admin_providers.dart' show firestoreProvider;
import '../data/snag_model.dart';
import '../data/snag_repository.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final snagRepositoryProvider = Provider<SnagRepository>((ref) {
  return FirestoreSnagRepository(ref.watch(firestoreProvider));
});

// ---------------------------------------------------------------------------
// Reads — family providers scoped per project. Views watch these, never
// cloud_firestore directly.
// ---------------------------------------------------------------------------

final snagsProvider = StreamProvider.family<List<SnagModel>, String>((ref, projectId) {
  return ref.watch(snagRepositoryProvider).watchSnags(projectId);
});

final allSnagsProvider = StreamProvider<List<SnagModel>>((ref) {
  return ref.watch(snagRepositoryProvider).watchAllSnags();
});

/// Open + In Progress snags for a project (derived, no extra query).
final openSnagsProvider = Provider.family<AsyncValue<List<SnagModel>>, String>((ref, projectId) {
  final snags = ref.watch(snagsProvider(projectId));
  return snags.whenData(
    (list) => list
        .where((s) => s.status == SnagStatus.open || s.status == SnagStatus.inProgress)
        .toList(),
  );
});

/// Resolved + Verified snags for a project (derived, no extra query).
final resolvedSnagsProvider =
    Provider.family<AsyncValue<List<SnagModel>>, String>((ref, projectId) {
  final snags = ref.watch(snagsProvider(projectId));
  return snags.whenData(
    (list) => list
        .where((s) => s.status == SnagStatus.resolved || s.status == SnagStatus.verified)
        .toList(),
  );
});

// ---------------------------------------------------------------------------
// Writes
// ---------------------------------------------------------------------------

class SnagFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(SnagModel snag) async {
    state = const AsyncLoading();
    final repo = ref.read(snagRepositoryProvider);
    state = await AsyncValue.guard(() {
      return snag.id.isEmpty ? repo.addSnag(snag) : repo.updateSnag(snag);
    });
  }

  Future<void> delete(String projectId, String snagId) async {
    state = const AsyncLoading();
    final repo = ref.read(snagRepositoryProvider);
    state = await AsyncValue.guard(() => repo.deleteSnag(projectId, snagId));
  }

  /// Fetches the next "SNAG-00N" ref for a new snag in this project.
  Future<String> nextRef(String projectId) {
    return ref.read(snagRepositoryProvider).nextRef(projectId);
  }
}

final snagFormControllerProvider = AsyncNotifierProvider<SnagFormController, void>(
  SnagFormController.new,
);

class SnagStatusController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateStatus(String projectId, String snagId, SnagStatus status) async {
    state = const AsyncLoading();
    final repo = ref.read(snagRepositoryProvider);
    state = await AsyncValue.guard(() => repo.updateStatus(projectId, snagId, status));
  }

  Future<void> assign(String projectId, String snagId, String userId) async {
    state = const AsyncLoading();
    final repo = ref.read(snagRepositoryProvider);
    state = await AsyncValue.guard(() => repo.assign(projectId, snagId, userId));
  }
}

final snagStatusControllerProvider = AsyncNotifierProvider<SnagStatusController, void>(
  SnagStatusController.new,
);
