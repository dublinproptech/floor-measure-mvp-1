import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dublin PropTech',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}