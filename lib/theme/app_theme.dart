import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema Material 3 + identidad teal de Mesa de Ayuda.
class AppTheme {
  // Compat con imports previos
  static const Color navy = AppColors.navy900;
  static const Color navyMid = AppColors.navy700;
  static const Color accent = AppColors.accent;
  static const Color bg = AppColors.bg;
  static const Color card = AppColors.card;
  static const Color muted = AppColors.muted;

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.brand600,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      tertiary: AppColors.brand600,
      surface: AppColors.card,
      onSurface: AppColors.slate900,
      surfaceContainerHighest: AppColors.slate100,
      outline: AppColors.slate200,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: AppTypography.textTheme,
      fontFamily: AppTypography.fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brand600,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate200,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.slate500),
        labelStyle: AppTypography.textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.brand600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand600,
          side: const BorderSide(color: AppColors.slate300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand600,
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slate100,
        selectedColor: AppColors.brand50,
        labelStyle: AppTypography.textTheme.labelMedium!,
        side: const BorderSide(color: AppColors.slate200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.slate200),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.brand50,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.textTheme.labelSmall!.copyWith(
            color: selected ? AppColors.brand600 : AppColors.slate500,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.brand600 : AppColors.slate500,
            size: 22,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand600,
        foregroundColor: AppColors.white,
        elevation: 2,
      ),
    );
  }
}

Color prioridadColor(String p) {
  switch (p) {
    case 'alta':
      return AppColors.danger;
    case 'baja':
      return AppColors.success;
    default:
      return AppColors.warning;
  }
}

Color prioridadSoft(String p) {
  switch (p) {
    case 'alta':
      return AppColors.dangerSoft;
    case 'baja':
      return AppColors.successSoft;
    default:
      return AppColors.warningSoft;
  }
}

/// Colores de impacto (distintos de prioridad: púrpura / azul / slate).
Color impactoColor(String p) {
  switch (p) {
    case 'alta':
      return AppColors.purple;
    case 'baja':
      return AppColors.slate500;
    default:
      return AppColors.info;
  }
}

Color impactoSoft(String p) {
  switch (p) {
    case 'alta':
      return AppColors.purpleSoft;
    case 'baja':
      return AppColors.slate100;
    default:
      return AppColors.infoSoft;
  }
}

Color estadoColor(String e) {
  switch (e) {
    case 'nuevo':
    case 'idea':
    case 'pendiente':
      return AppColors.info;
    case 'por_aprobar':
      return AppColors.warning;
    case 'planificado':
      return AppColors.brand600;
    case 'en_proceso':
    case 'en_progreso':
      return AppColors.warning;
    case 'esperando':
    case 'pausado':
      return AppColors.purple;
    case 'resuelto':
    case 'completado':
    case 'hecho':
      return AppColors.success;
    case 'cancelado':
    case 'rechazado':
      return AppColors.danger;
    case 'cerrado':
      return AppColors.slate500;
    default:
      return AppColors.muted;
  }
}

Color estadoSoft(String e) {
  switch (e) {
    case 'nuevo':
    case 'idea':
    case 'pendiente':
      return AppColors.infoSoft;
    case 'por_aprobar':
      return AppColors.warningSoft;
    case 'planificado':
      return AppColors.brand50;
    case 'en_proceso':
    case 'en_progreso':
      return AppColors.warningSoft;
    case 'esperando':
    case 'pausado':
      return AppColors.purpleSoft;
    case 'resuelto':
    case 'completado':
    case 'hecho':
      return AppColors.successSoft;
    case 'cancelado':
    case 'rechazado':
      return AppColors.dangerSoft;
    case 'cerrado':
      return AppColors.slate100;
    default:
      return AppColors.slate100;
  }
}

String labelEstado(String e) {
  const map = {
    'nuevo': 'Nuevo',
    'por_aprobar': 'Por aprobar',
    'en_proceso': 'En Proceso',
    'esperando': 'Esperando',
    'resuelto': 'Resuelto',
    'rechazado': 'Rechazado',
    'cerrado': 'Cerrado',
    'idea': 'En Idea',
    'planificado': 'Planificado',
    'pausado': 'Pausado',
    'completado': 'Completado',
    'cancelado': 'Cancelado',
    // Tarea states
    'pendiente': 'Pendiente',
    'en_progreso': 'En progreso',
    'hecho': 'Hecho',
  };
  return map[e] ?? e;
}

String labelPrioridad(String p) {
  const map = {'alta': 'Alta', 'media': 'Media', 'baja': 'Baja'};
  return map[p] ?? p;
}
