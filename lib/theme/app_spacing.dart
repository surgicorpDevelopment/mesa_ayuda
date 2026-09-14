import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const double maxContentWidth = 1200;
  static const double sidebarExpanded = 240;
  static const double sidebarCollapsed = 72;

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: AppColors.navy900.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: AppColors.navy900.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: AppColors.navy900.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: AppColors.navy900.withValues(alpha: 0.10),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: AppColors.navy900.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
