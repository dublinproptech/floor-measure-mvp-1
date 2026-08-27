import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_settings_model.dart';
import '../../../data/models/flooring_type_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/flooring_type_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';

// ---------------------------------------------------------------------------
// Shared infra (move to core/providers.dart once Phase 0 foundation lands —
// kept here for now so this feature works standalone).
// ---------------------------------------------------------------------------

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final flooringTypeRepositoryProvider = Provider<FlooringTypeRepository>((ref) {
  return FirestoreFlooringTypeRepository(ref.watch(firestoreProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return FirestoreSettingsRepository(ref.watch(firestoreProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});

// ---------------------------------------------------------------------------
// Reads (streams) — Views watch these directly, never cloud_firestore.
// ---------------------------------------------------------------------------

final flooringTypesProvider = StreamProvider<List<FlooringTypeModel>>((ref) {
  return ref.watch(flooringTypeRepositoryProvider).watchFlooringTypes();
});

final settingsProvider = StreamProvider<AppSettingsModel>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});

final usersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).watchUsers();
});

// ---------------------------------------------------------------------------
// Writes (notifiers) — Views call these, get loading/error state back.
// ---------------------------------------------------------------------------

class FlooringTypeFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(FlooringTypeModel type) async {
    state = const AsyncLoading();
    final repo = ref.read(flooringTypeRepositoryProvider);
    state = await AsyncValue.guard(() {
      return type.id.isEmpty ? repo.addFlooringType(type) : repo.updateFlooringType(type);
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    final repo = ref.read(flooringTypeRepositoryProvider);
    state = await AsyncValue.guard(() => repo.deleteFlooringType(id));
  }
}

final flooringTypeFormControllerProvider =
    AsyncNotifierProvider<FlooringTypeFormController, void>(
  FlooringTypeFormController.new,
);

class SettingsFormController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(AppSettingsModel settings) async {
    state = const AsyncLoading();
    final repo = ref.read(settingsRepositoryProvider);
    state = await AsyncValue.guard(() => repo.updateSettings(settings));
  }
}

final settingsFormControllerProvider = AsyncNotifierProvider<SettingsFormController, void>(
  SettingsFormController.new,
);

class UserRoleController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateRole(String userId, UserRole role) async {
    state = const AsyncLoading();
    final repo = ref.read(userRepositoryProvider);
    state = await AsyncValue.guard(() => repo.updateUserRole(userId, role));
  }
}

final userRoleControllerProvider = AsyncNotifierProvider<UserRoleController, void>(
  UserRoleController.new,
);
