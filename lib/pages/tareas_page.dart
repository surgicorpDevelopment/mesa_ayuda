import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ui/ui.dart';

/// Lista simple de tareas asignadas al usuario, filtrada por estado.
class MisTareasPage extends StatefulWidget {
  const MisTareasPage({super.key, required this.estado});

  /// `pendiente` o `en_progreso`.
  final String estado;

  @override
  State<MisTareasPage> createState() => _MisTareasPageState();
}

class _MisTareasPageState extends State<MisTareasPage> {
  List<Tarea> _items = [];
  Map<int, String> _proyectoTitulos = {};
  bool _loading = true;
  String? _error;

  String get _titulo =>
      widget.estado == 'en_progreso' ? 'Tareas en progreso' : 'Tareas pendientes';

  String get _emptyMsg => widget.estado == 'en_progreso'
      ? 'No tienes tareas en progreso'
      : 'No tienes tareas pendientes';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MisTareasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.estado != widget.estado) {
      _load();
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
      final filtered = allTareas
          .where((t) => t.asignadoAId == userId && t.estado == widget.estado)
          .toList()
        ..sort((a, b) {
          final da =
              a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db =
              b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });

      final titulos = <int, String>{};
      if (filtered.isNotEmpty) {
        final proyectos = await auth.api.fetchProyectos();
        for (final p in proyectos) {
          titulos[p.id] = p.titulo;
        }
      }

      if (!mounted) return;
      setState(() {
        _items = filtered;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.brand600,
        foregroundColor: AppColors.white,
        title: Text(_titulo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Inicio',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      AppEmptyState(message: _error!, icon: Icons.error_outline),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      SectionHeader(
                        title: _titulo,
                        subtitle: _items.isEmpty
                            ? 'Asignadas a ti · ninguna'
                            : 'Asignadas a ti · ${_items.length}',
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        AppEmptyState(
                          message: _emptyMsg,
                          icon: Icons.task_alt_rounded,
                        )
                      else
                        ..._items.asMap().entries.map((e) {
                          final t = e.value;
                          final proyecto = _proyectoTitulos[t.proyectoId];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              hoverable: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              onTap: () =>
                                  context.go('/proyectos/${t.proyectoId}'),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.titulo,
                                          style:
                                              AppTypography.textTheme.titleSmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          proyecto ??
                                              'Proyecto #${t.proyectoId}',
                                          style:
                                              AppTypography.textTheme.bodySmall,
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
                          ).animate().fadeIn(delay: (40 * e.key).ms);
                        }),
                    ],
                  ),
      ),
    );
  }
}
