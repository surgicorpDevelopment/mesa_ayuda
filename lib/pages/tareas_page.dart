import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/bandeja.dart';
import '../widgets/ui/ui.dart';

/// Tareas propias o del equipo, con el mismo criterio de bandeja que Inicio y Tickets.
class MisTareasPage extends StatefulWidget {
  const MisTareasPage({super.key, this.ruta = const RutaBandeja()});

  final RutaBandeja ruta;

  @override
  State<MisTareasPage> createState() => _MisTareasPageState();
}

class _MisTareasPageState extends State<MisTareasPage> {
  List<Tarea> _items = [];
  Map<int, String> _proyectoTitulos = {};
  bool _loading = true;
  String? _error;
  String _alcance = 'yo';
  int? _personaId;
  /// null = abiertas. `pendiente` | `en_progreso` | `hecho`
  String? _estado;

  @override
  void initState() {
    super.initState();
    _aplicarRuta();
    _load();
  }

  @override
  void didUpdateWidget(MisTareasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final antes = oldWidget.ruta;
    final ahora = widget.ruta;
    if (antes.alcance != ahora.alcance ||
        antes.estado != ahora.estado ||
        antes.personaId != ahora.personaId) {
      setState(_aplicarRuta);
    }
  }

  void _aplicarRuta() {
    _alcance = widget.ruta.alcance;
    _personaId = widget.ruta.personaId;
    _estado = widget.ruta.estado;
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
      final proyectos = await auth.api.fetchProyectos();
      final titulos = <int, String>{
        for (final p in proyectos) p.id: p.titulo,
      };

      if (!mounted) return;
      setState(() {
        _items = allTareas;
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

  List<Tarea> _filtradas(
    int? yoId, {
    required String alcance,
    int? personaId,
    String? estado,
  }) {
    return tareasDeAlcance(
      _items,
      alcance: alcance,
      yoId: yoId,
      personaId: personaId,
      estado: estado,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;
    final yoCount = _filtradas(userId, alcance: 'yo').length;
    final equipoCount = _filtradas(userId, alcance: 'equipo').length;
    final enEquipo = _alcance == 'equipo' || _alcance == 'persona';
    final personas = _personas(userId);
    final titulo = _alcance == 'persona' ? _nombrePersona(personas) : enEquipo ? 'Equipo' : 'Mis tareas';

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
                SectionHeader(
                  title: titulo,
                  subtitle: enEquipo
                      ? 'Tareas abiertas de los demás, por persona y proyecto'
                      : 'Tareas abiertas asignadas a ti',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TareaTile(
                      label: 'Yo',
                      count: yoCount,
                      color: AppColors.brand600,
                      soft: AppColors.brand50,
                      selected: _alcance == 'yo',
                      onTap: () => setState(() {
                        _alcance = 'yo';
                        _personaId = null;
                        _estado = null;
                      }),
                    ),
                    _TareaTile(
                      label: 'Equipo',
                      count: equipoCount,
                      color: AppColors.info,
                      soft: AppColors.infoSoft,
                      selected: enEquipo && _personaId == null,
                      onTap: () => setState(() {
                        _alcance = 'equipo';
                        _personaId = null;
                        _estado = null;
                      }),
                    ),
                    if (personas.isNotEmpty)
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('tarea-persona-$_personaId-$_alcance'),
                          initialValue: _alcance == 'persona' ? _personaId : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Persona',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: [
                            for (final p in personas)
                              DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.nombre} · ${p.tareasAbiertas}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (id) {
                            if (id == null) return;
                            setState(() {
                              _alcance = 'persona';
                              _personaId = id;
                              _estado = null;
                            });
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _estadoChips(userId))
                      _TareaTile(
                        label: c.label,
                        count: c.count,
                        color: c.color,
                        soft: c.soft,
                        selected: _estado == c.id,
                        onTap: () => setState(() {
                          _estado = _estado == c.id ? null : c.id;
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
                      : _buildLista(userId),
            ),
          ),
        ],
      ),
    );
  }

  List<CargaPersona> _personas(int? userId) {
    final personas = <CargaPersona>[
      ...cargasPorPersona(
        tickets: const [],
        tareas: _items,
        excluirId: userId,
        soloConAbiertos: false,
      ),
    ];
    if (_personaId != null && !personas.any((p) => p.id == _personaId)) {
      personas.insert(0, CargaPersona(id: _personaId!, nombre: 'Usuario #$_personaId'));
    }
    return personas;
  }

  String _nombrePersona(List<CargaPersona> personas) {
    for (final p in personas) {
      if (p.id == _personaId) return p.nombre;
    }
    return 'Persona';
  }

  List<({String? id, String label, int count, Color color, Color soft})> _estadoChips(int? userId) {
    int count(String? estado) => _filtradas(
      userId,
      alcance: _alcance == 'persona' ? 'persona' : _alcance,
      personaId: _alcance == 'persona' ? _personaId : null,
      estado: estado,
    ).length;
    return [
      (
        id: null,
        label: 'Abiertas',
        count: count(null),
        color: AppColors.brand600,
        soft: AppColors.brand50,
      ),
      (
        id: 'pendiente',
        label: 'Pendientes',
        count: count('pendiente'),
        color: AppColors.info,
        soft: AppColors.infoSoft,
      ),
      (
        id: 'en_progreso',
        label: 'En progreso',
        count: count('en_progreso'),
        color: AppColors.warning,
        soft: AppColors.warningSoft,
      ),
      (
        id: 'hecho',
        label: 'Hechas',
        count: count('hecho'),
        color: AppColors.success,
        soft: AppColors.successSoft,
      ),
    ];
  }

  Widget _buildLista(int? userId) {
    if (_alcance == 'yo') {
      final sections = _estado == null
          ? const ['pendiente', 'en_progreso']
          : [_estado!];
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
        children: [
          for (final estado in sections)
            _section(
              estado,
              _filtradas(userId, alcance: 'yo', estado: estado),
            ),
        ],
      );
    }

    final items = _filtradas(
      userId,
      alcance: _alcance == 'persona' ? 'persona' : 'equipo',
      personaId: _alcance == 'persona' ? _personaId : null,
      estado: _estado,
    );
    if (items.isEmpty) {
      return ListView(
        children: const [
          AppEmptyState(
            message: 'No hay tareas abiertas en esta bandeja',
            icon: Icons.task_alt_rounded,
          ),
        ],
      );
    }

    final porPersona = <int, List<Tarea>>{};
    for (final t in items) {
      final id = t.asignadoAId;
      if (id == null) continue;
      porPersona.putIfAbsent(id, () => []).add(t);
    }
    final personas = porPersona.keys.toList()
      ..sort((a, b) {
        final ca = porPersona[a]!.length;
        final cb = porPersona[b]!.length;
        if (ca != cb) return cb.compareTo(ca);
        return _nombreDe(porPersona[a]!.first).compareTo(_nombreDe(porPersona[b]!.first));
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
      children: [
        for (final id in personas) _bloquePersona(id, porPersona[id]!),
      ],
    );
  }

  String _nombreDe(Tarea t) {
    final n = t.asignadoANombre?.trim() ?? '';
    return n.isEmpty ? 'Usuario #${t.asignadoAId}' : n;
  }

  Widget _bloquePersona(int id, List<Tarea> tareas) {
    final porProyecto = <int, List<Tarea>>{};
    for (final t in tareas) {
      porProyecto.putIfAbsent(t.proyectoId, () => []).add(t);
    }
    final espera = tareas.where(tareaEnEspera).length;
    final quietas = tareas.where(tareaSinMovimiento).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              AppAvatar(name: _nombreDe(tareas.first), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_nombreDe(tareas.first)} · ${tareas.length}',
                  style: AppTypography.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (espera > 0)
                Text(
                  'En espera · $espera',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (quietas > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'Sin movimiento · $quietas',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final entry in porProyecto.entries) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              _proyectoTitulos[entry.key] ?? 'Proyecto #${entry.key}',
              style: AppTypography.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final t in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tareaCard(t),
            ),
        ],
      ],
    );
  }

  Widget _section(String estado, List<Tarea> items) {
    final label = switch (estado) {
      'en_progreso' => 'En progreso',
      'hecho' => 'Hechas',
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
            child: Text(empty, style: AppTypography.textTheme.bodySmall),
          )
        else
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tareaCard(t, tacharHecha: estado == 'hecho'),
            ),
      ],
    );
  }

  Widget _tareaCard(Tarea t, {bool tacharHecha = false}) {
    final espera = etiquetaEspera(t);
    final quieta = tareaSinMovimiento(t);
    final hecha = tacharHecha || t.estado == 'hecho';
    return AppCard(
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
                    color: hecha ? AppColors.slate500 : null,
                    decoration: hecha ? TextDecoration.lineThrough : null,
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
                if (espera != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    espera,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (quieta) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Sin movimiento',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusBadge.estado(t.estado),
        ],
      ),
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
          width: 148,
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
