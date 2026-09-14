import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.softColor,
    this.showDot = true,
  });

  final String label;
  final Color color;
  final Color? softColor;
  final bool showDot;

  factory StatusBadge.estado(String estado) {
    return StatusBadge(
      label: labelEstado(estado),
      color: estadoColor(estado),
      softColor: estadoSoft(estado),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = softColor ?? color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({super.key, required this.prioridad});

  final String prioridad;

  @override
  Widget build(BuildContext context) {
    final color = prioridadColor(prioridad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: prioridadSoft(prioridad),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            labelPrioridad(prioridad),
            style: AppTypography.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
