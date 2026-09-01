import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth.dart';
import '../admin/application/admin_providers.dart' show userRepositoryProvider;


class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {

  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final cred = await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = cred.user;
        if (user != null) {
          await ref.read(userRepositoryProvider).ensureUserDoc(
            uid: user.uid,
            email: user.email ?? email.trim(),
            name: user.displayName ?? '',
          );
        }
      } on FirebaseAuthException catch (e) {
        throw AuthFailure(_messageFromCode(e.code));
      }
    });
  }

  Future<void> signOut() => ref.read(firebaseAuthProvider).signOut();

  String _messageFromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return "That email address doesn't look right.";
      case 'user-disabled':
        return 'This account has been disabled. Contact your admin.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

}