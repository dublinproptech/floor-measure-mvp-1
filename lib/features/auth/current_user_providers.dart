import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth.dart';
import '../../data/models/user_model.dart';
import '../admin/application/admin_providers.dart' show firestoreProvider;

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider).asData?.value;
  if (auth == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(auth.uid)
      .snapshots()
      .map((d) => d.exists ? UserModel.fromMap(d.id, d.data()!) : null);
});

final isAdminProvider = Provider<bool>((ref) =>
ref.watch(currentUserProvider).asData?.value?.role == UserRole.admin);