import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.fontSize,
  });

  final String name;
  final double size;
  final double? fontSize;

  Color _colorFromName(String value) {
    const palette = [
      AppColors.brand600,
      AppColors.navy700,
      AppColors.accent,
      AppColors.purple,
      AppColors.success,
      AppColors.info,
    ];
    final hash = value.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFromName(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _initials(name),
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: color,
          fontSize: fontSize ?? (size * 0.34),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
