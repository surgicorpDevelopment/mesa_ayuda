import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ui.dart';

enum _PeriodoFiltro { semana, mes, dias30 }

class ProductividadPage extends StatefulWidget {
  const ProductividadPage({super.key});

  @override
  State<ProductividadPage> createState() => _ProductividadPageState();
}

class _ProductividadPageState extends State<ProductividadPage> {
  _PeriodoFiltro _periodo = _PeriodoFiltro.semana;
  ProductividadReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) _rangeFor(_PeriodoFiltro p) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    switch (p) {
      case _PeriodoFiltro.semana:
        final weekday = hoy.weekday; // 1=Mon
        final inicio = hoy.subtract(Duration(days: weekday - 1));
        return (inicio, hoy);
      case _PeriodoFiltro.mes:
        return (DateTime(hoy.year, hoy.month, 1), hoy);
      case _PeriodoFiltro.dias30:
        return (hoy.subtract(const Duration(days: 29)), hoy);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (desde, hasta) = _rangeFor(_periodo);
      final report = await context.read<AuthProvider>().api.fetchProductividad(
            desde: desde,
            hasta: hasta,
          );
      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _relativeTime(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ranking = _report?.ranking ?? const <ProductividadRanking>[];
    final actividad = _report?.actividad ?? const <ProductividadEvento>[];
    final maxTotal = ranking.isEmpty
        ? 1
        : ranking.map((r) => r.total).fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Reportes',
                  subtitle: 'Productividad del equipo de desarrollo',
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in [
                        (_PeriodoFiltro.semana, 'Esta semana'),
                        (_PeriodoFiltro.mes, 'Este mes'),
                        (_PeriodoFiltro.dias30, 'Últimos 30 días'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(entry.$2),
                            selected: _periodo == entry.$1,
                            onSelected: (_) {
                              setState(() => _periodo = entry.$1);
                              _load();
                            },
                            selectedColor: AppColors.brand50,
                            checkmarkColor: AppColors.brand600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const AppSkeletonList(count: 4)
                  : _error != null
                      ? ListView(
                          children: [
                            AppEmptyState(message: _error!, icon: Icons.error_outline),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
                          children: [
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'Ranking',
                                    subtitle: '${ranking.length} desarrolladores',
                                  ),
                                  const SizedBox(height: 12),
                                  if (ranking.isEmpty)
                                    Text(
                                      'Sin actividad en este período.',
                                      style: AppTypography.textTheme.bodySmall,
                                    )
                                  else
                                    ...ranking.asMap().entries.map((entry) {
                                      final i = entry.key;
                                      final r = entry.value;
                                      final progress = r.total / maxTotal;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 28,
                                                  child: Text(
                                                    '#${i + 1}',
                                                    style: AppTypography.textTheme.labelMedium?.copyWith(
                                                      color: AppColors.slate500,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                AppAvatar(name: r.nombre, size: 32),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        r.nombre,
                                                        style: AppTypography.textTheme.titleSmall,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 4,
                                                        children: [
                                                          _MetricChip(
                                                            icon: Icons.task_alt_rounded,
                                                            label: '${r.tareasHechas} tareas',
                                                            color: AppColors.success,
                                                          ),
                                                          _MetricChip(
                                                            icon: Icons.confirmation_number_outlined,
                                                            label: '${r.ticketsResueltos} tickets',
                                                            color: AppColors.info,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: progress.clamp(0.0, 1.0),
                                                minHeight: 6,
                                                backgroundColor: AppColors.slate100,
                                                color: AppColors.brand600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn(delay: (40 * i).ms);
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'Actividad reciente',
                                    subtitle: '${actividad.length} eventos',
                                  ),
                                  const SizedBox(height: 12),
                                  if (actividad.isEmpty)
                                    Text(
                                      'No hay cambios de estado en este período.',
                                      style: AppTypography.textTheme.bodySmall,
                                    )
                                  else
                                    ...actividad.map((e) => _TimelineTile(
                                          evento: e,
                                          relative: _relativeTime(e.fecha),
                                        )),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.evento, required this.relative});

  final ProductividadEvento evento;
  final String relative;

  @override
  Widget build(BuildContext context) {
    final isTarea = evento.tipo == 'tarea';
    final color = estadoColor(evento.estadoNuevo);
    final soft = estadoSoft(evento.estadoNuevo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTarea ? Icons.task_alt_rounded : Icons.confirmation_number_outlined,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.titulo,
                  style: AppTypography.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      evento.usuarioNombre ?? 'Sin usuario',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        labelEstado(evento.estadoNuevo),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      isTarea ? 'Tarea' : 'Ticket',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            relative,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}
