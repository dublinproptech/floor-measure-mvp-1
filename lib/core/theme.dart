import 'package:flutter/material.dart';

class AppColors {
  static const gold      = Color(0xFFC17F22); // --gold: accent, focus, selected
  static const goldLight = Color(0xFFE8B955); // --gold-light
  static const goldDeep  = Color(0xFFA06818); // --gold-deep
  static const ink       = Color(0xFF1C1A17); // --ink: text + primary button
  static const paper     = Color(0xFFFAF8F4); // --paper: page background
  static const card      = Color(0xFFFFFFFF); // --card: surface
  static const line      = Color(0xFFE6DDD0); // --line: borders
  static const muted     = Color(0xFF8A8078); // --muted: secondary text
  static const danger    = Color(0xFFB0453A); // --danger
  static const label     = Color(0xFF555555); // form label color
}

const double kRadius = 10; // --radius

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.gold,
    surface: AppColors.card,
    error: AppColors.danger,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    // fontFamily intentionally unset: the reference uses the OS system font,
    // which on Android is Roboto (Flutter's default). Matches with no bundling.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.muted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gold, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}