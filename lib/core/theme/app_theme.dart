import 'package:flutter/material.dart';

/// Единая палитра приложения, снятая с макетов из demo_app_screenshots.
abstract final class AppColors {
  static const teal = Color(0xFF6BB3AC);
  static const tealDark = Color(0xFF549A94);
  static const tealPale = Color(0xFFE3F2F0);
  static const tealPale2 = Color(0xFFD9EFE7);
  static const headerCell = Color(0xFFBFE3DE);
  static const ink = Color(0xFF2F3A3A);
  static const inkLight = Color(0xFF7A8B8B);
  static const cardBg = Colors.white;
  static const pageBg = Color(0xFFF7FAFA);
  static const overlayDim = Color(0x99000000);
}

/// Типографика и формы переиспользуются через тему, чтобы не дублировать стили.
ThemeData buildAppTheme() {
  const seed = AppColors.teal;
  final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
    primary: AppColors.tealDark,
    secondary: AppColors.teal,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.pageBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.teal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.teal.withAlpha(140)),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
  );
}
