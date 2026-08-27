import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/projects/presentation/project_list_screen.dart';
import '../features/projects/presentation/project_form_screen.dart';
import '../features/projects/presentation/project_detail_screen.dart';
import '../features/projects/data/project_model.dart';

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
      GoRoute(path: '/projects', builder: (_, _) => const ProjectListScreen()),
      GoRoute(path: '/projects/new', builder: (_, _) => const ProjectFormScreen()),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) =>
            ProjectDetailScreen(projectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/projects/:id/edit',
        builder: (context, state) =>
            ProjectFormScreen(existing: state.extra as ProjectModel?),
      ),
    ],
  );
});