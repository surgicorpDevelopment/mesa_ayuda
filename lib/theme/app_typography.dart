import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  /// Stack del sistema (Segoe UI en Windows). Inter se puede empaquetar después en assets/fonts.
  static const String fontFamily = 'Segoe UI';

  static TextTheme textTheme = const TextTheme(
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.slate900,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.slate900,
      height: 1.25,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.slate900,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.slate900,
      height: 1.35,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.slate900,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.slate900,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.slate700,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.slate700,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.slate500,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.slate900,
      height: 1.2,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.slate700,
      height: 1.2,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: AppColors.slate500,
      height: 1.2,
    ),
  );
}
