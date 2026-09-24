import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/date_format.dart';
import '../widgets/common_widgets.dart';
import '../widgets/ui/ui.dart';

class ProyectosListPage extends StatefulWidget {
  const ProyectosListPage({super.key});

  @override
  State<ProyectosListPage> createState() => _ProyectosListPageState();
}

class _ProyectosListPageState extends State<ProyectosListPage> {
  List<Proyecto> _items = [];
  Map<int, List<Tarea>> _tareasByProject = {};
  bool _loading = true;
  String? _error;
  String? _estadoFilter;
  /// `inicio_prox` | `inicio_lejos` | `fin_prox` | `recientes` | `prioridad_alta`
  String _sortBy = 'inicio_prox';

  static int _prioridadRank(String p) {
    switch (p) {
      case 'alta':
        return 0;
      case 'media':
        return 1;
      case 'baja':
        return 2;
      default:
        return 3;
    }
  }

  static DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
  static DateTime _far = DateTime(9999);

  void _applySort(List<Proyecto> items) {
    int cmpDate(DateTime? a, DateTime? b, {required bool ascending}) {
      final da = a ?? (ascending ? _far : _epoch);
      final db = b ?? (ascending ? _far : _epoch);
      return ascending ? da.compareTo(db) : db.compareTo(da);
    }

    switch (_sortBy) {
      case 'inicio_lejos':
        items.sort((a, b) => cmpDate(a.fechaInicio, b.fechaInicio, ascending: false));
      case 'fin_prox':
        items.sort((a, b) => cmpDate(a.fechaObjetivo, b.fechaObjetivo, ascending: true));
      case 'recientes':
        items.sort(
          (a, b) => cmpDate(a.fechaActualizacion, b.fechaActualizacion, ascending: false),
        );
      case 'prioridad_alta':
        items.sort((a, b) {
          final c = _prioridadRank(a.prioridad).compareTo(_prioridadRank(b.prioridad));
          if (c != 0) return c;
          return cmpDate(a.fechaInicio, b.fechaInicio, ascending: true);
        });
      case 'inicio_prox':
      default:
        items.sort((a, b) => cmpDate(a.fechaInicio, b.fechaInicio, ascending: true));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final filters = <String, String>{};
      if (_estadoFilter != null) filters['estado'] = _estadoFilter!;
      final items = await api.fetchProyectos(filters: filters);
      final allTareas = await api.fetchTareas();
      final map = <int, List<Tarea>>{};
      for (final t in allTareas) {
        map.putIfAbsent(t.proyectoId, () => []).add(t);
      }
      _applySort(items);
      if (mounted) {
        setState(() {
          _items = items;
          _tareasByProject = map;
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

  double _progress(int projectId) {
    final list = _tareasByProject[projectId] ?? [];
    if (list.isEmpty) return 0;
    final done = list.where((t) => t.estado == 'hecho').length;
    return done / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        context.watch<AuthProvider>().user?.canManageProyectos == true;
    final estados = [
      null,
      'idea',
      'planificado',
      'en_proceso',
      'pausado',
      'completado',
      'cancelado',
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/proyectos/nuevo'),
              icon: const Icon(Icons.add),
              label: const Text('Proyecto'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Proyectos',
                  subtitle: '${_items.length} proyectos',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final e in estados)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label:
                                      Text(e == null ? 'Todos' : labelEstado(e)),
                                  selected: _estadoFilter == e,
                                  onSelected: (_) {
                                    setState(() => _estadoFilter = e);
                                    _load();
                                  },
                                  selectedColor: AppColors.brand50,
                                  checkmarkColor: AppColors.brand600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<String>(
                        initialValue: _sortBy,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Ordenar',
                          prefixIcon: Icon(Icons.sort, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'inicio_prox',
                            child: Text('Inicio · más próximo'),
                          ),
                          DropdownMenuItem(
                            value: 'inicio_lejos',
                            child: Text('Inicio · más lejano'),
                          ),
                          DropdownMenuItem(
                            value: 'fin_prox',
                            child: Text('Fin · más próximo'),
                          ),
                          DropdownMenuItem(
                            value: 'recientes',
                            child: Text('Más recientes'),
                          ),
                          DropdownMenuItem(
                            value: 'prioridad_alta',
                            child: Text('Prioridad · alta primero'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _sortBy = v;
                            final sorted = List<Proyecto>.from(_items);
                            _applySort(sorted);
                            _items = sorted;
                          });
                        },
                      ),
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
                  ? const AppSkeletonList(count: 3)
                  : _error != null
                  ? ListView(
                      children: [
                        AppEmptyState(
                          message: _error!,
                          icon: Icons.error_outline,
                        ),
                      ],
                    )
                  : _items.isEmpty
                  ? ListView(
                      children: const [
                        AppEmptyState(message: 'No hay proyectos'),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            mainAxisExtent: 268,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final p = _items[i];
                        final progress = _progress(p.id);
                        final tareaCount =
                            (_tareasByProject[p.id] ?? []).length;
                        return AppCard(
                          hoverable: true,
                          onTap: () => context.go('/proyectos/${p.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTypography.textTheme.titleMedium,
                                    ),
                                  ),
                                  StatusBadge.estado(p.estado),
                                ],
                              ),
                              if (p.atrasado) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: StatusBadge(
                                    label: 'Atrasado',
                                    color: AppColors.danger,
                                    softColor: AppColors.dangerSoft,
                                    showDot: false,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  p.descripcion.isEmpty
                                      ? 'Sin descripción'
                                      : p.descripcion,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (p.areaNombre != null &&
                                  p.areaNombre!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_outlined,
                                      size: 14,
                                      color: AppColors.slate500,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        p.areaNombre!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.slate500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                formatDateRange(p.fechaInicio, p.fechaFin),
                                style: AppTypography.textTheme.labelSmall
                                    ?.copyWith(
                                      color: p.atrasado
                                          ? AppColors.danger
                                          : AppColors.slate500,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  AppAvatar(
                                    name: p.responsableNombre ?? '—',
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.responsableNombre ?? 'Sin responsable',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    '$tareaCount tareas',
                                    style: AppTypography.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: AppColors.slate100,
                                  color: AppColors.brand600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(progress * 100).round()}% completado',
                                style: AppTypography.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (30 * i).ms);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProyectoFormPage extends StatefulWidget {
  const ProyectoFormPage({super.key});

  @override
  State<ProyectoFormPage> createState() => _ProyectoFormPageState();
}

class _ProyectoFormPageState extends State<ProyectoFormPage> {
  final _titulo = TextEditingController();
  final _desc = TextEditingController();
  String _prioridad = 'media';
  String _estado = 'idea';
  int? _areaId;
  int? _responsableId;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<AreaOption> _areas = [];
  List<AssignableUser> _responsables = [];
  bool _loadingAreas = false;
  bool _loadingResponsables = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _areaId = user?.areaId;
    _responsableId = user?.id;
    if (user?.isLider == true) _loadAreas();
    _loadResponsables();
  }

  Future<void> _loadAreas() async {
    setState(() => _loadingAreas = true);
    try {
      final list = await context.read<AuthProvider>().api.fetchAreas();
      if (mounted)
        setState(() {
          _areas = list;
          _loadingAreas = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _loadResponsables() async {
    setState(() => _loadingResponsables = true);
    try {
      final list = await context
          .read<AuthProvider>()
          .api
          .fetchAssignableUsers();
      if (!mounted) return;
      setState(() {
        _responsables = list;
        _loadingResponsables = false;
        // Asegura que el usuario actual esté en la lista aunque no venga del API.
        final me = context.read<AuthProvider>().user;
        if (me != null && !_responsables.any((u) => u.id == me.id)) {
          _responsables = [
            AssignableUser(
              id: me.id,
              fullName: me.fullName,
              username: me.username,
            ),
            ..._responsables,
          ];
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingResponsables = false);
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titulo.text.trim().isEmpty) return;
    if (_fechaInicio != null &&
        _fechaFin != null &&
        DateTime(
          _fechaInicio!.year,
          _fechaInicio!.month,
          _fechaInicio!.day,
        ).isAfter(
          DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de inicio no puede ser posterior a la fecha fin.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final proyecto = await auth.api.createProyecto({
        'titulo': _titulo.text.trim(),
        'descripcion': _desc.text.trim(),
        'prioridad': _prioridad,
        'estado': _estado,
        'area_id': _areaId ?? auth.user?.areaId,
        'responsable': _responsableId ?? auth.user?.id,
        'fecha_inicio': _fechaInicio?.toIso8601String().split('T').first,
        'fecha_objetivo': _fechaFin?.toIso8601String().split('T').first,
      });
      if (!mounted) return;
      context.go('/proyectos/${proyecto.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLider = context.watch<AuthProvider>().user?.isLider == true;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nuevo proyecto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/proyectos'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(controller: _titulo, label: 'Título'),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _desc,
                      label: 'Descripción',
                      minLines: 4,
                      maxLines: 8,
                    ),
                    // Selector de área solo para gestores/líderes
                    if (isLider) ...[
                      const SizedBox(height: 14),
                      if (_loadingAreas)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      else
                        DropdownButtonFormField<int?>(
                          initialValue: _areaId,
                          decoration: const InputDecoration(
                            labelText: 'Área',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Sin área'),
                            ),
                            for (final a in _areas)
                              DropdownMenuItem<int?>(
                                value: a.id,
                                child: Text(a.nombre),
                              ),
                          ],
                          onChanged: (v) => setState(() => _areaId = v),
                        ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _estado,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: const [
                        DropdownMenuItem(value: 'idea', child: Text('En Idea')),
                        DropdownMenuItem(
                          value: 'planificado',
                          child: Text('Planificado'),
                        ),
                        DropdownMenuItem(
                          value: 'en_proceso',
                          child: Text('En Proceso'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _estado = v ?? 'idea'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _prioridad,
                      decoration: const InputDecoration(labelText: 'Prioridad'),
                      items: const [
                        DropdownMenuItem(value: 'alta', child: Text('Alta')),
                        DropdownMenuItem(value: 'media', child: Text('Media')),
                        DropdownMenuItem(value: 'baja', child: Text('Baja')),
                      ],
                      onChanged: (v) =>
                          setState(() => _prioridad = v ?? 'media'),
                    ),
                    const SizedBox(height: 14),
                    if (_loadingResponsables)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else
                      DropdownButtonFormField<int?>(
                        key: ValueKey(_responsableId),
                        initialValue: _responsableId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Responsable',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sin responsable'),
                          ),
                          for (final u in _responsables)
                            DropdownMenuItem<int?>(
                              value: u.id,
                              child: Text(
                                u.fullName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _responsableId = v),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DateField(
                            label: 'Fecha inicio',
                            value: _fechaInicio,
                            onChanged: (v) => setState(() => _fechaInicio = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DateField(
                            label: 'Fecha fin',
                            value: _fechaFin,
                            onChanged: (v) => setState(() => _fechaFin = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Crear proyecto',
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                      expanded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProyectoDetailPage extends StatefulWidget {
  const ProyectoDetailPage({
    super.key,
    required this.id,
    this.initialTab,
  });

  final int id;
  /// `tareas` abre la pestaña Kanban; cualquier otro valor (o null) abre Detalle.
  final String? initialTab;

  @override
  State<ProyectoDetailPage> createState() => _ProyectoDetailPageState();
}

class _ProyectoDetailPageState extends State<ProyectoDetailPage>
    with SingleTickerProviderStateMixin {
  Proyecto? _proyecto;
  List<Tarea> _tareas = [];
  List<AssignableUser> _usuarios = [];
  List<AreaOption> _areas = [];
  List<HistorialEstado> _historial = [];
  bool _loading = true;
  String? _error;
  bool _savingAdjunto = false;
  bool _loadingHistorial = false;
  bool _deleting = false;
  bool _savingTexto = false;
  bool _editingTexto = false;

  final _titulo = TextEditingController();
  final _desc = TextEditingController();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'tareas' ? 1 : 0,
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titulo.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _syncTextoFromProyecto(Proyecto p) {
    _titulo.text = p.titulo;
    _desc.text = p.descripcion;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final canManage =
          context.read<AuthProvider>().user?.canManageProyectos == true;
      final futures = <Future>[
        api.fetchProyecto(widget.id),
        api.fetchTareas(proyectoId: widget.id),
        api.fetchAssignableUsers(),
      ];
      if (canManage) futures.add(api.fetchAreas());
      final results = await Future.wait(futures);
      if (mounted) {
        final p = results[0] as Proyecto;
        setState(() {
          _proyecto = p;
          _tareas = results[1] as List<Tarea>;
          _usuarios = results[2] as List<AssignableUser>;
          if (results.length > 3) _areas = results[3] as List<AreaOption>;
          _loading = false;
          _editingTexto = false;
        });
        _syncTextoFromProyecto(p);
        _loadHistorial();
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

  Future<void> _loadHistorial() async {
    if (!mounted) return;
    setState(() => _loadingHistorial = true);
    try {
      final list = await context.read<AuthProvider>().api.fetchHistorial(
        'proyecto',
        widget.id,
      );
      if (mounted) {
        setState(() {
          _historial = list;
          _loadingHistorial = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistorial = false);
    }
  }

  List<AssignableUser> get _dropdownResponsables {
    final seen = <int>{};
    final list = <AssignableUser>[];
    for (final u in _usuarios) {
      if (seen.add(u.id)) list.add(u);
    }
    final p = _proyecto;
    if (p?.responsableId != null && seen.add(p!.responsableId!)) {
      list.insert(
        0,
        AssignableUser(
          id: p.responsableId!,
          fullName: p.responsableNombre ?? 'Usuario #${p.responsableId}',
        ),
      );
    }
    return list;
  }

  List<AreaOption> get _areasDistinct {
    final seen = <int>{};
    final list = <AreaOption>[];
    for (final a in _areas) {
      if (seen.add(a.id)) list.add(a);
    }
    return list;
  }

  Future<void> _setEstado(String estado) async {
    try {
      final p = await context.read<AuthProvider>().api.updateProyecto(
        widget.id,
        {'estado': estado},
      );
      if (mounted) setState(() => _proyecto = p);
      await _loadHistorial();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _setPrioridad(String prioridad) async {
    try {
      final p = await context.read<AuthProvider>().api.updateProyecto(
        widget.id,
        {'prioridad': prioridad},
      );
      if (mounted) setState(() => _proyecto = p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _setResponsable(int? responsableId) async {
    try {
      final p = await context.read<AuthProvider>().api.updateProyecto(
        widget.id,
        {'responsable': responsableId},
      );
      if (mounted) setState(() => _proyecto = p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _setArea(int? areaId) async {
    try {
      final p = await context.read<AuthProvider>().api.updateProyecto(
        widget.id,
        {'area_id': areaId},
      );
      if (mounted) setState(() => _proyecto = p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _startEditTexto() {
    final p = _proyecto;
    if (p == null) return;
    _syncTextoFromProyecto(p);
    setState(() => _editingTexto = true);
  }

  void _cancelEditTexto() {
    final p = _proyecto;
    if (p != null) _syncTextoFromProyecto(p);
    setState(() => _editingTexto = false);
  }

  Future<void> _saveTexto() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título no puede estar vacío.')),
      );
      return;
    }
    setState(() => _savingTexto = true);
    try {
      final p = await context.read<AuthProvider>().api.updateProyecto(
        widget.id,
        {'titulo': titulo, 'descripcion': _desc.text.trim()},
      );
      if (!mounted) return;
      setState(() {
        _proyecto = p;
        _editingTexto = false;
      });
      _syncTextoFromProyecto(p);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Proyecto actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _savingTexto = false);
    }
  }

  Future<void> _setFechas({DateTime? inicio, DateTime? fin}) async {
    if (inicio != null &&
        fin != null &&
        DateTime(
          inicio.year,
          inicio.month,
          inicio.day,
        ).isAfter(DateTime(fin.year, fin.month, fin.day))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de inicio no puede ser posterior a la fecha fin.',
          ),
        ),
      );
      return;
    }
    try {
      final p = await context.read<AuthProvider>().api.updateProyecto(
        widget.id,
        {
          'fecha_inicio': inicio?.toIso8601String().split('T').first,
          'fecha_objetivo': fin?.toIso8601String().split('T').first,
        },
      );
      if (mounted) setState(() => _proyecto = p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addAdjuntos(List<TicketAdjunto> nuevos) async {
    if (_savingAdjunto) return;
    setState(() => _savingAdjunto = true);
    try {
      final api = context.read<AuthProvider>().api;
      Proyecto updated = _proyecto!;
      for (final adj in nuevos) {
        updated = await api.addProyectoAdjunto(widget.id, adj);
      }
      if (mounted) setState(() => _proyecto = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _savingAdjunto = false);
    }
  }

  Future<void> _removeAdjunto(TicketAdjunto adj) async {
    if (_savingAdjunto) return;
    setState(() => _savingAdjunto = true);
    try {
      final updated = await context
          .read<AuthProvider>()
          .api
          .removeProyectoAdjunto(widget.id, adj.id);
      if (mounted) setState(() => _proyecto = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _savingAdjunto = false);
    }
  }

  // ── Kanban: mover tarea de columna ─────────────────────────────────────

  Future<void> _moveTarea(Tarea tarea, String nuevoEstado) async {
    // Optimistic update
    setState(() {
      final i = _tareas.indexWhere((t) => t.id == tarea.id);
      if (i >= 0) {
        _tareas[i] = Tarea(
          id: tarea.id,
          titulo: tarea.titulo,
          descripcion: tarea.descripcion,
          estado: nuevoEstado,
          asignadoAId: tarea.asignadoAId,
          asignadoANombre: tarea.asignadoANombre,
          proyectoId: tarea.proyectoId,
          esperando: tarea.esperando,
          fechaCreacion: tarea.fechaCreacion,
          fechaActualizacion: DateTime.now(),
        );
      }
    });
    try {
      final updated = await context.read<AuthProvider>().api.updateTarea(
        tarea.id,
        {'estado': nuevoEstado},
      );
      if (mounted) {
        setState(() {
          final i = _tareas.indexWhere((t) => t.id == updated.id);
          if (i >= 0) _tareas[i] = updated;
        });
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          final i = _tareas.indexWhere((t) => t.id == tarea.id);
          if (i >= 0) _tareas[i] = tarea;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  // ── Kanban: crear tarea ─────────────────────────────────────────────────

  Future<void> _createTarea(
    String titulo,
    String estado,
    int? asignadoAId,
    List<TareaEspera> esperando,
  ) async {
    try {
      final tarea = await context.read<AuthProvider>().api.createTarea({
        'titulo': titulo,
        'estado': estado,
        'proyecto': widget.id,
        if (asignadoAId != null) 'asignado_a': asignadoAId,
        'esperando': esperando.map((e) => e.toJson()).toList(),
      });
      if (mounted) setState(() => _tareas.add(tarea));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  // ── Kanban: eliminar tarea ─────────────────────────────────────────────

  Future<void> _deleteTarea(Tarea tarea) async {
    setState(() => _tareas.removeWhere((t) => t.id == tarea.id));
    try {
      await context.read<AuthProvider>().api.deleteTarea(tarea.id);
    } catch (e) {
      // Restore on failure
      if (mounted) {
        setState(() => _tareas.add(tarea));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  // ── Kanban: editar tarea ───────────────────────────────────────────────

  Future<void> _updateTarea(
    Tarea tarea, {
    required String titulo,
    required String descripcion,
    required int? asignadoAId,
    required List<TareaEspera> esperando,
  }) async {
    try {
      final updated = await context.read<AuthProvider>().api.updateTarea(
        tarea.id,
        {
          'titulo': titulo,
          'descripcion': descripcion,
          'asignado_a': asignadoAId,
          'esperando': esperando.map((e) => e.toJson()).toList(),
        },
      );
      if (mounted) {
        setState(() {
          final i = _tareas.indexWhere((t) => t.id == updated.id);
          if (i >= 0) _tareas[i] = updated;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmDelete() async {
    final nTareas = _tareas.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Eliminar "${_proyecto?.titulo ?? 'este proyecto'}"?\n'
          '${nTareas > 0 ? 'También se borrarán $nTareas tarea(s). ' : ''}'
          'Se borrarán comentarios, historial y adjuntos. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await context.read<AuthProvider>().api.deleteProyecto(widget.id);
      if (!mounted) return;
      context.go('/proyectos');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canManage =
        context.watch<AuthProvider>().user?.canManageProyectos == true;
    final canDelete = context.watch<AuthProvider>().user?.isLider == true;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Material(
          color: AppColors.brand600,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () => context.go('/proyectos'),
                    tooltip: 'Volver',
                  ),
                  if (!_loading && _error == null)
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.white,
                        unselectedLabelColor: AppColors.slate300,
                        indicatorColor: AppColors.white,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        dividerHeight: 0,
                        tabs: [
                          const Tab(text: 'Detalle', height: 40),
                          Tab(text: 'Tareas (${_tareas.length})', height: 40),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
          ? AppEmptyState(message: _error!, icon: Icons.error_outline)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetalleTab(canManage, canDelete),
                _buildTareasTab(),
              ],
            ),
    );
  }

  Widget _buildDetalleTab(bool canManage, bool canDelete) {
    final p = _proyecto!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge.estado(p.estado),
                  PriorityIndicator(prioridad: p.prioridad),
                  if (p.atrasado)
                    const StatusBadge(
                      label: 'Atrasado',
                      color: AppColors.danger,
                      softColor: AppColors.dangerSoft,
                      showDot: false,
                      width: StatusBadge.badgeWidth,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_editingTexto && canManage) ...[
                AppTextField(controller: _titulo, label: 'Título'),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _desc,
                  label: 'Descripción',
                  minLines: 4,
                  maxLines: 10,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppButton(
                      label: 'Cancelar',
                      variant: AppButtonVariant.ghost,
                      onPressed: _savingTexto ? null : _cancelEditTexto,
                    ),
                    const Spacer(),
                    AppButton(
                      label: 'Guardar',
                      loading: _savingTexto,
                      onPressed: _savingTexto ? null : _saveTexto,
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        p.titulo,
                        style: AppTypography.textTheme.titleLarge,
                      ),
                    ),
                    if (canManage)
                      IconButton(
                        tooltip: 'Editar título y descripción',
                        onPressed: _startEditTexto,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.descripcion.isEmpty ? 'Sin descripción' : p.descripcion,
                  style: AppTypography.textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 16),
              if (canManage) ...[
                DropdownButtonFormField<int?>(
                  key: ValueKey('area-${p.areaId}'),
                  initialValue: p.areaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Área',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin área'),
                    ),
                    for (final a in _areasDistinct)
                      DropdownMenuItem<int?>(
                        value: a.id,
                        child: Text(a.nombre),
                      ),
                    if (p.areaId != null &&
                        !_areasDistinct.any((a) => a.id == p.areaId))
                      DropdownMenuItem<int?>(
                        value: p.areaId,
                        child: Text(p.areaNombre ?? 'Área #${p.areaId}'),
                      ),
                  ],
                  onChanged: _setArea,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  key: ValueKey('resp-${p.responsableId}'),
                  initialValue: p.responsableId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Responsable',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin responsable'),
                    ),
                    for (final u in _dropdownResponsables)
                      DropdownMenuItem<int?>(
                        value: u.id,
                        child: Text(
                          u.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _setResponsable,
                ),
              ] else ...[
                if (p.areaNombre != null && p.areaNombre!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 16,
                          color: AppColors.slate500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.areaNombre!,
                          style: AppTypography.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    AppAvatar(name: p.responsableNombre ?? '—', size: 30),
                    const SizedBox(width: 8),
                    Text(
                      'Responsable: ${p.responsableNombre ?? "—"}',
                      style: AppTypography.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (canManage)
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        label: 'Fecha inicio',
                        value: p.fechaInicio,
                        onChanged: (v) =>
                            _setFechas(inicio: v, fin: p.fechaFin),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DateField(
                        label: 'Fecha fin',
                        value: p.fechaFin,
                        onChanged: (v) =>
                            _setFechas(inicio: p.fechaInicio, fin: v),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  formatDateRange(p.fechaInicio, p.fechaFin),
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: p.atrasado ? AppColors.danger : AppColors.slate500,
                  ),
                ),
              const SizedBox(height: 16),
              AttachmentGallery(
                adjuntos: p.adjuntos,
                onAdd: _addAdjuntos,
                onRemove: _removeAdjunto,
                saving: _savingAdjunto,
              ),
              if (canManage) ...[
                const SizedBox(height: 16),
                Text('Estado', style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in [
                      'idea',
                      'planificado',
                      'en_proceso',
                      'pausado',
                      'completado',
                      'cancelado',
                    ])
                      ColorChip(
                        label: labelEstado(e),
                        selected: p.estado == e,
                        color: estadoColor(e),
                        softColor: estadoSoft(e),
                        onTap: () => _setEstado(e),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Prioridad', style: AppTypography.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final pr in ['alta', 'media', 'baja'])
                      ColorChip(
                        label: labelPrioridad(pr),
                        selected: p.prioridad == pr,
                        color: prioridadColor(pr),
                        softColor: prioridadSoft(pr),
                        onTap: () => _setPrioridad(pr),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: ComentariosPanel(
            tipo: 'proyecto',
            refId: widget.id,
            load: () => context.read<AuthProvider>().api.fetchComentarios(
              'proyecto',
              widget.id,
            ),
            onSubmit: (c) => context.read<AuthProvider>().api.createComentario(
              'proyecto',
              widget.id,
              c,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: HistorialPanel(items: _historial, loading: _loadingHistorial),
        ),
        if (canDelete) ...[
          const SizedBox(height: 16),
          AppButton(
            label: 'Eliminar proyecto',
            icon: Icons.delete_outline,
            variant: AppButtonVariant.danger,
            expanded: true,
            loading: _deleting,
            onPressed: _deleting ? null : _confirmDelete,
          ),
        ],
      ],
    );
  }

  Widget _buildTareasTab() {
    final puedeBorrar = context.read<AuthProvider>().user?.isLider == true;
    return KanbanBoard(
      tareas: _tareas,
      usuarios: _usuarios,
      onMove: _moveTarea,
      onCreate: _createTarea,
      onDelete: puedeBorrar ? _deleteTarea : null,
      onUpdate: _updateTarea,
    );
  }
}
