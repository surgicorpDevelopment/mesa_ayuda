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
    this.width,
  });

  /// Ancho fijo compartido con [PriorityIndicator] (cubre "En Proceso" / "Planificado").
  static const double badgeWidth = 108;

  /// Alias histórico.
  static const double estadoWidth = badgeWidth;

  final String label;
  final Color color;
  final Color? softColor;
  final bool showDot;
  final double? width;

  factory StatusBadge.estado(String estado, {double? width = badgeWidth}) {
    return StatusBadge(
      label: labelEstado(estado),
      color: estadoColor(estado),
      softColor: estadoSoft(estado),
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = softColor ?? color.withValues(alpha: 0.12);
    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (width == null)
            Text(
              label,
              style: AppTypography.textTheme.labelMedium?.copyWith(color: color),
            )
          else
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({
    super.key,
    required this.prioridad,
    this.width = StatusBadge.badgeWidth,
  });

  /// Mismo ancho que [StatusBadge.badgeWidth].
  static const double priorityWidth = StatusBadge.badgeWidth;

  final String prioridad;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final color = prioridadColor(prioridad);
    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: prioridadSoft(prioridad),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              labelPrioridad(prioridad),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
