import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Chip de selección con color semántico propio.
///
/// - Seleccionado : fondo soft + borde + texto del color indicado + ícono ✓.
/// - No seleccionado: fondo blanco, borde gris, texto gris.
///
/// Úsalo para Estado, Prioridad e Impacto en tickets y proyectos.
class ColorChip extends StatelessWidget {
  const ColorChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.softColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? softColor : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.slate200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(Icons.check_rounded, size: 13, color: color),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? color : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
