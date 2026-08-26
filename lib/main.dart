import 'package:floor_measure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: FloorMeasureApp()));
}

class FloorMeasureApp extends ConsumerWidget {
  const FloorMeasureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Floor Measure',
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
