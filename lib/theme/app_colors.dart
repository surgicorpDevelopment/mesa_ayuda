import 'package:flutter/material.dart';

/// Paleta corporativa alineada al portal de picking (navy + brand blue + accent).
class AppColors {
  AppColors._();

  static const Color navy900 = Color(0xFF0B2545);
  static const Color navy700 = Color(0xFF17365D);
  static const Color navy500 = Color(0xFF2A4A6F);

  static const Color brand600 = Color(0xFF1565C0);
  static const Color brand500 = Color(0xFF1E78D6);
  static const Color brand50 = Color(0xFFE8F1FB);

  static const Color accent = Color(0xFFE8722A);
  static const Color accentSoft = Color(0xFFFFF0E6);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFEDE9FE);

  static const Color white = Colors.white;
  static const Color bg = slate50;
  static const Color card = white;
  static const Color muted = slate500;

  // Compat aliases usados en código previo
  static const Color navy = navy900;
  static const Color navyMid = navy700;
}
