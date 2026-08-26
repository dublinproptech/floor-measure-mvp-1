import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Session not resolved yet (cold start restoring the saved user).
      final resolved = authState.asData != null || authState.hasError;
      if (!resolved) return loc == '/splash' ? null : '/splash';

      final loggedIn = authState.asData?.value != null;
      final inAuthArea = loc == '/login' || loc == '/splash';

      if (!loggedIn) return loc == '/login' ? null : '/login';
      if (inAuthArea) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    ],
  );
});