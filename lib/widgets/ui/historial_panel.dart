import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/date_format.dart';
import 'section_header.dart';

class HistorialPanel extends StatelessWidget {
  const HistorialPanel({
    super.key,
    required this.items,
    this.loading = false,
  });

  final List<HistorialEstado> items;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Historial de estado'),
        const SizedBox(height: 12),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (items.isEmpty)
          Text(
            'Aún no hay cambios de estado.',
            style: AppTypography.textTheme.bodySmall,
          )
        else
          ...[
            for (var i = 0; i < items.length; i++)
              _HistorialTile(
                item: items[i],
                isLast: i == items.length - 1,
              ),
          ],
      ],
    );
  }
}

class _HistorialTile extends StatelessWidget {
  const _HistorialTile({required this.item, required this.isLast});

  final HistorialEstado item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = estadoColor(item.estadoNuevo);
    final soft = estadoSoft(item.estadoNuevo);
    final fromLabel = item.estadoAnterior.isEmpty ? 'Creado' : labelEstado(item.estadoAnterior);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.timeline, size: 16, color: color),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.only(top: 4),
                  color: AppColors.slate200,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      fromLabel,
                      style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                    ),
                    const Icon(Icons.arrow_forward, size: 12, color: AppColors.slate500),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        labelEstado(item.estadoNuevo),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.usuarioNombre ?? 'Sin usuario',
                  style: AppTypography.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRelative(item.fecha),
            style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
