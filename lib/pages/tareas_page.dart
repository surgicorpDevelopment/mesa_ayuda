import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ui.dart';

/// Tareas asignadas al usuario: pendientes, en progreso y hechas.
class MisTareasPage extends StatefulWidget {
  const MisTareasPage({super.key, this.initialFilter});

  /// `pendiente`, `en_progreso`, `hecho` o null (las tres secciones).
  final String? initialFilter;

  @override
  State<MisTareasPage> createState() => _MisTareasPageState();
}

class _MisTareasPageState extends State<MisTareasPage> {
  List<Tarea> _items = [];
  Map<int, String> _proyectoTitulos = {};
  bool _loading = true;
  String? _error;
  String? _filtro;

  @override
  void initState() {
    super.initState();
    _filtro = widget.initialFilter;
    _load();
  }

  @override
  void didUpdateWidget(MisTareasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() => _filtro = widget.initialFilter);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id;
      if (userId == null) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }

      final allTareas = await auth.api.fetchTareas();
      final mine = allTareas
          .where((t) =>
              t.asignadoAId == userId &&
              (t.estado == 'pendiente' ||
                  t.estado == 'en_progreso' ||
                  t.estado == 'hecho'))
          .toList()
        ..sort((a, b) {
          final da = a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });

      final titulos = <int, String>{};
      if (mine.isNotEmpty) {
        final proyectos = await auth.api.fetchProyectos();
        for (final p in proyectos) {
          titulos[p.id] = p.titulo;
        }
      }

      if (!mounted) return;
      setState(() {
        _items = mine;
        _proyectoTitulos = titulos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Tarea> _of(String estado) =>
      _items.where((t) => t.estado == estado).toList();

  @override
  Widget build(BuildContext context) {
    final pendientes = _of('pendiente');
    final enProgreso = _of('en_progreso');
    final hechas = _of('hecho');
    final sections = _filtro == null
        ? const ['pendiente', 'en_progreso', 'hecho']
        : [_filtro!];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Tareas',
                  subtitle: 'Asignadas a ti en proyectos',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TareaTile(
                      label: 'Pendientes',
                      count: pendientes.length,
                      color: AppColors.info,
                      soft: AppColors.infoSoft,
                      selected: _filtro == 'pendiente',
                      onTap: () => setState(() {
                        _filtro = _filtro == 'pendiente' ? null : 'pendiente';
                      }),
                    ),
                    _TareaTile(
                      label: 'En progreso',
                      count: enProgreso.length,
                      color: AppColors.warning,
                      soft: AppColors.warningSoft,
                      selected: _filtro == 'en_progreso',
                      onTap: () => setState(() {
                        _filtro = _filtro == 'en_progreso' ? null : 'en_progreso';
                      }),
                    ),
                    _TareaTile(
                      label: 'Hechos',
                      count: hechas.length,
                      color: AppColors.success,
                      soft: AppColors.successSoft,
                      selected: _filtro == 'hecho',
                      onTap: () => setState(() {
                        _filtro = _filtro == 'hecho' ? null : 'hecho';
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const AppSkeletonList()
                  : _error != null
                      ? ListView(
                          children: [
                            AppEmptyState(message: _error!, icon: Icons.error_outline),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
                          children: [
                            for (final estado in sections) ...[
                              _section(estado, _of(estado)),
                            ],
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String estado, List<Tarea> items) {
    final label = switch (estado) {
      'en_progreso' => 'En progreso',
      'hecho' => 'Hechos',
      _ => 'Pendientes',
    };
    final empty = switch (estado) {
      'en_progreso' => 'No tienes tareas en progreso',
      'hecho' => 'Aún no tienes tareas hechas',
      _ => 'No tienes tareas pendientes',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            '$label · ${items.length}',
            style: AppTypography.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              empty,
              style: AppTypography.textTheme.bodySmall,
            ),
          )
        else
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                hoverable: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => context.go('/proyectos/${t.proyectoId}?tab=tareas'),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: estadoColor(t.estado),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.titulo,
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              color: estado == 'hecho' ? AppColors.slate500 : null,
                              decoration: estado == 'hecho'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _proyectoTitulos[t.proyectoId] ?? 'Proyecto #${t.proyectoId}',
                            style: AppTypography.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge.estado(t.estado),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _TareaTile extends StatelessWidget {
  const _TareaTile({
    required this.label,
    required this.count,
    required this.color,
    required this.soft,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final Color soft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? soft : AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.slate200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
