import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/sistemas_catalog.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/date_format.dart';
import '../widgets/common_widgets.dart';
import '../widgets/ui/ui.dart';

class TicketsListPage extends StatefulWidget {
  const TicketsListPage({
    super.key,
    this.onlyAssignedToMe = false,
    this.onlyUnassigned = false,
  });

  final bool onlyAssignedToMe;
  final bool onlyUnassigned;

  @override
  State<TicketsListPage> createState() => _TicketsListPageState();
}

class _TicketsListPageState extends State<TicketsListPage> {
  List<Ticket> _items = [];
  bool _loading = true;
  String? _error;
  String? _estadoFilter;
  String _query = '';
  int _countMine = 0;
  int _countUnassigned = 0;
  /// `recientes` | `prioridad_alta` | `prioridad_baja`
  String _sortBy = 'prioridad_alta';

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

  void _applySort(List<Ticket> items) {
    switch (_sortBy) {
      case 'prioridad_alta':
        items.sort((a, b) {
          final c = _prioridadRank(a.prioridad).compareTo(_prioridadRank(b.prioridad));
          if (c != 0) return c;
          final da = a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      case 'prioridad_baja':
        items.sort((a, b) {
          final c = _prioridadRank(b.prioridad).compareTo(_prioridadRank(a.prioridad));
          if (c != 0) return c;
          final da = a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      default:
        items.sort((a, b) {
          final da = a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TicketsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onlyAssignedToMe != widget.onlyAssignedToMe ||
        oldWidget.onlyUnassigned != widget.onlyUnassigned) {
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
      final filters = <String, String>{};
      if (_estadoFilter != null) filters['estado'] = _estadoFilter!;
      if (widget.onlyAssignedToMe && auth.user != null) {
        filters['asignado_a'] = '${auth.user!.id}';
      }

      // Contadores de los chips: independientes del filtro activo.
      final inbox = await auth.api.fetchInbox();
      final countMine = inbox.asignadosAMi;
      final countUnassigned = inbox.colaSinAsignar;

      var items = await auth.api.fetchTickets(filters: filters);
      if (widget.onlyUnassigned) {
        items = items
            .where((t) =>
                t.asignadoAId == null &&
                t.estado != 'resuelto' &&
                t.estado != 'cerrado')
            .toList();
      }
      if (_query.trim().isNotEmpty) {
        final q = _query.toLowerCase();
        items = items
            .where((t) =>
                t.titulo.toLowerCase().contains(q) ||
                t.sistemaAfectado.toLowerCase().contains(q) ||
                (t.asignadoANombre ?? '').toLowerCase().contains(q))
            .toList();
      }
      _applySort(items);
      if (mounted) {
        setState(() {
          _items = items;
          _countMine = countMine;
          _countUnassigned = countUnassigned;
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDev = user?.isDesarrollador == true;
    final estados = [null, 'nuevo', 'en_proceso', 'esperando', 'resuelto', 'cerrado'];
    final listTitle = widget.onlyUnassigned
        ? 'Cola sin asignar'
        : widget.onlyAssignedToMe
            ? 'Mis abiertos'
            : 'Tickets';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/tickets/nuevo'),
        icon: const Icon(Icons.add),
        label: Text(isDev ? 'Ticket' : 'Reportar incidencia'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: listTitle,
                  subtitle: '${_items.length} resultados',
                ),
                if (isDev) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        selected: !widget.onlyAssignedToMe && !widget.onlyUnassigned,
                        onSelected: (_) => context.go('/tickets'),
                        selectedColor: AppColors.brand50,
                        checkmarkColor: AppColors.brand600,
                        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                          color: !widget.onlyAssignedToMe && !widget.onlyUnassigned
                              ? AppColors.brand600
                              : AppColors.slate700,
                        ),
                      ),
                      Tooltip(
                        message:
                            'Asignados a ti en Nuevo, En proceso o Esperando.\nNo incluye resueltos ni cerrados.',
                        child: FilterChip(
                          label: Text('Mis abiertos ($_countMine)'),
                          selected: widget.onlyAssignedToMe,
                          onSelected: (_) => context.go('/tickets?mine=1'),
                          selectedColor: AppColors.brand50,
                          checkmarkColor: AppColors.brand600,
                          labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                            color: widget.onlyAssignedToMe
                                ? AppColors.brand600
                                : AppColors.slate700,
                          ),
                        ),
                      ),
                      FilterChip(
                        label: Text('Sin asignar ($_countUnassigned)'),
                        selected: widget.onlyUnassigned,
                        onSelected: (_) => context.go('/tickets?unassigned=1'),
                        selectedColor: AppColors.brand50,
                        checkmarkColor: AppColors.brand600,
                        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                          color: widget.onlyUnassigned
                              ? AppColors.brand600
                              : AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        hint: 'Buscar por título, sistema o responsable…',
                        onChanged: (v) {
                          _query = v;
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 200,
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
                            value: 'prioridad_alta',
                            child: Text('Prioridad · alta primero'),
                          ),
                          DropdownMenuItem(
                            value: 'prioridad_baja',
                            child: Text('Prioridad · baja primero'),
                          ),
                          DropdownMenuItem(
                            value: 'recientes',
                            child: Text('Más recientes'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _sortBy = v;
                            final sorted = List<Ticket>.from(_items);
                            _applySort(sorted);
                            _items = sorted;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final e in estados)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(e == null ? 'Todos' : labelEstado(e)),
                            selected: _estadoFilter == e,
                            onSelected: (_) {
                              setState(() => _estadoFilter = e);
                              _load();
                            },
                            selectedColor: AppColors.brand50,
                            checkmarkColor: AppColors.brand600,
                            labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                              color: _estadoFilter == e ? AppColors.brand600 : AppColors.slate700,
                            ),
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
                  ? const AppSkeletonList()
                  : _error != null
                      ? ListView(children: [AppEmptyState(message: _error!, icon: Icons.error_outline)])
                      : _items.isEmpty
                          ? ListView(children: const [AppEmptyState(message: 'No hay tickets')])
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final t = _items[i];
                                return AppCard(
                                  hoverable: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  onTap: () => context.go('/tickets/${t.id}'),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.titulo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.textTheme.titleSmall,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              t.sistemaAfectado.isEmpty
                                                  ? 'Sin sistema'
                                                  : SistemaAfectadoCatalog.labelFor(t.sistemaAfectado),
                                              style: AppTypography.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            AppAvatar(
                                              name: t.asignadoANombre ?? 'Sin asignar',
                                              size: 28,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                t.asignadoANombre ?? 'Sin asignar',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.textTheme.bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge.estado(t.estado),
                                      const SizedBox(width: 10),
                                      PriorityIndicator(prioridad: t.prioridad),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 88,
                                        child: Text(
                                          formatRelative(t.fechaCreacion),
                                          textAlign: TextAlign.right,
                                          style: AppTypography.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: (20 * i).ms);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketFormPage extends StatefulWidget {
  const TicketFormPage({super.key, this.proyectoId});

  /// Si viene desde un proyecto, se pre-vincula automáticamente.
  final int? proyectoId;

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final _titulo = TextEditingController();
  final _desc = TextEditingController();
  final _sistemaOtro = TextEditingController();
  String? _sistema;
  String _prioridad = 'media';
  String _impacto = 'media';
  bool _saving = false;
  List<TicketAdjunto> _adjuntos = [];
  List<SistemaOption> _sistemas = SistemaAfectadoCatalog.options;
  bool _loadingSistemas = true;
  String? _proyectoTitulo; // label de solo lectura cuando viene pre-vinculado

  @override
  void initState() {
    super.initState();
    _loadSistemas();
    if (widget.proyectoId != null) _loadProyectoTitulo();
  }

  Future<void> _loadProyectoTitulo() async {
    try {
      final p = await context.read<AuthProvider>().api.fetchProyecto(widget.proyectoId!);
      if (mounted) setState(() => _proyectoTitulo = p.titulo);
    } catch (_) {
      if (mounted) setState(() => _proyectoTitulo = 'Proyecto #${widget.proyectoId}');
    }
  }

  Future<void> _loadSistemas() async {
    try {
      final list = await context.read<AuthProvider>().api.fetchSistemas();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _sistemas = list;
          _loadingSistemas = false;
        });
        return;
      }
    } catch (_) {
      // Fallback al catálogo local
    }
    if (mounted) {
      setState(() {
        _sistemas = SistemaAfectadoCatalog.options;
        _loadingSistemas = false;
      });
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    _sistemaOtro.dispose();
    super.dispose();
  }

  String get _sistemaAfectadoValue {
    if (_sistema == null || _sistema!.isEmpty) return '';
    if (_sistema == 'otro') {
      final otro = _sistemaOtro.text.trim();
      return otro.isEmpty ? 'otro' : otro;
    }
    return _sistema!;
  }

  Future<void> _save() async {
    if (_titulo.text.trim().isEmpty) return;
    if (_sistema == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el sistema afectado')),
      );
      return;
    }
    if (_sistema == 'otro' && _sistemaOtro.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el nombre del sistema')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final isDev = auth.user?.isDesarrollador == true;
      final ticket = await auth.api.createTicket({
        'titulo': _titulo.text.trim(),
        'descripcion': _desc.text.trim(),
        'sistema_afectado': _sistemaAfectadoValue,
        if (isDev) ...{
          'prioridad': _prioridad,
          'impacto': _impacto,
        },
        if (widget.proyectoId != null) 'proyecto': widget.proyectoId,
        'adjuntos': _adjuntos.map((a) => a.toJson()).toList(),
      });
      if (!mounted) return;
      context.go('/tickets/${ticket.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDev = context.watch<AuthProvider>().user?.isDesarrollador == true;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(isDev ? 'Nuevo ticket' : 'Reportar incidencia'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/tickets')),
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
                    AppTextField(controller: _titulo, label: 'Título', hint: 'Describe el problema en una línea'),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _desc,
                      label: 'Descripción',
                      minLines: 4,
                      maxLines: 8,
                      hint: 'Pasos, impacto y contexto',
                    ),
                    const SizedBox(height: 14),
                    ScreenshotPicker(
                      adjuntos: _adjuntos,
                      onChanged: (v) => setState(() => _adjuntos = v),
                    ),
                    const SizedBox(height: 14),
                    Text('Sistema afectado', style: AppTypography.textTheme.labelMedium),
                    const SizedBox(height: 6),
                    if (_loadingSistemas)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _sistema,
                        decoration: const InputDecoration(
                          hintText: 'Selecciona una aplicación o sistema',
                          prefixIcon: Icon(Icons.desktop_windows_outlined),
                        ),
                        items: [
                          for (final o in _sistemas)
                            DropdownMenuItem(
                              value: o.value,
                              child: Text(o.label),
                            ),
                        ],
                        onChanged: (v) => setState(() => _sistema = v),
                      ),
                    if (_sistema == 'power_apps') ...[
                      const SizedBox(height: 6),
                      Text(
                        'Usa esta opción para las apps de Power Platform. Puedes aclarar cuál en la descripción.',
                        style: AppTypography.textTheme.bodySmall,
                      ),
                    ],
                    if (_sistema == 'otro') ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _sistemaOtro,
                        label: 'Nombre del sistema',
                        hint: 'Ej: portal representantes, app XX…',
                      ),
                    ],
                    if (isDev) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _prioridad,
                              decoration: const InputDecoration(labelText: 'Prioridad'),
                              items: const [
                                DropdownMenuItem(value: 'alta', child: Text('Alta')),
                                DropdownMenuItem(value: 'media', child: Text('Media')),
                                DropdownMenuItem(value: 'baja', child: Text('Baja')),
                              ],
                              onChanged: (v) => setState(() => _prioridad = v ?? 'media'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _impacto,
                              decoration: const InputDecoration(labelText: 'Impacto'),
                              items: const [
                                DropdownMenuItem(value: 'alta', child: Text('Alta')),
                                DropdownMenuItem(value: 'media', child: Text('Media')),
                                DropdownMenuItem(value: 'baja', child: Text('Baja')),
                              ],
                              onChanged: (v) => setState(() => _impacto = v ?? 'media'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Campo de proyecto (solo lectura cuando viene pre-vinculado)
                    if (widget.proyectoId != null) ...[
                      const SizedBox(height: 14),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Proyecto vinculado',
                          prefixIcon: Icon(Icons.folder_outlined),
                        ),
                        child: Text(
                          _proyectoTitulo ?? 'Cargando…',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppButton(label: 'Crear ticket', loading: _saving, onPressed: _saving ? null : _save, expanded: true),
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

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({super.key, required this.id});

  final int id;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  Ticket? _ticket;
  bool _loading = true;
  String? _error;
  List<AssignableUser> _assignees = [];
  bool _loadingAssignees = false;
  bool _savingAdjunto = false;
  List<HistorialEstado> _historial = [];
  bool _loadingHistorial = false;
  bool _deleting = false;
  bool _editingTexto = false;
  bool _savingTexto = false;

  final _titulo = TextEditingController();
  final _desc = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _syncTextoFromTicket(Ticket t) {
    _titulo.text = t.titulo;
    _desc.text = t.descripcion;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final t = await api.fetchTicket(widget.id);
      if (mounted) {
        setState(() {
          _ticket = t;
          _loading = false;
          _editingTexto = false;
        });
        _syncTextoFromTicket(t);
      }
      _loadAssignees();
      _loadHistorial();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadAssignees() async {
    final user = context.read<AuthProvider>().user;
    if (user?.isDesarrollador != true) return;
    setState(() => _loadingAssignees = true);
    try {
      final list = await context.read<AuthProvider>().api.fetchAssignableUsers();
      if (mounted) {
        setState(() {
          _assignees = list;
          _loadingAssignees = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAssignees = false);
    }
  }

  Future<void> _loadHistorial() async {
    if (!mounted) return;
    setState(() => _loadingHistorial = true);
    try {
      final list = await context.read<AuthProvider>().api.fetchHistorial('ticket', widget.id);
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

  List<AssignableUser> get _dropdownUsers {
    final list = List<AssignableUser>.from(_assignees);
    final t = _ticket;
    if (t?.asignadoAId != null && !list.any((u) => u.id == t!.asignadoAId)) {
      list.insert(
        0,
        AssignableUser(
          id: t!.asignadoAId!,
          fullName: t.asignadoANombre ?? 'Usuario #${t.asignadoAId}',
        ),
      );
    }
    return list;
  }

  Future<void> _patch(Map<String, dynamic> body) async {
    try {
      final t = await context.read<AuthProvider>().api.updateTicket(widget.id, body);
      if (mounted) setState(() => _ticket = t);
      if (body.containsKey('estado')) await _loadHistorial();
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
      Ticket updated = _ticket!;
      for (final adj in nuevos) {
        updated = await api.addAdjunto(widget.id, adj);
      }
      if (mounted) setState(() => _ticket = updated);
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
      final updated = await context.read<AuthProvider>().api.removeAdjunto(widget.id, adj.id);
      if (mounted) setState(() => _ticket = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _savingAdjunto = false);
    }
  }

  Future<void> _tomar() async {
    try {
      final t = await context.read<AuthProvider>().api.takeTicket(widget.id);
      if (mounted) {
        setState(() => _ticket = t);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket tomado')),
        );
      }
      await _loadHistorial();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  bool get _canEditTexto {
    final user = context.read<AuthProvider>().user;
    final t = _ticket;
    if (user == null || t == null) return false;
    return user.isDesarrollador || t.reportadoPorId == user.id;
  }

  void _startEditTexto() {
    final t = _ticket;
    if (t == null) return;
    _syncTextoFromTicket(t);
    setState(() => _editingTexto = true);
  }

  void _cancelEditTexto() {
    final t = _ticket;
    if (t != null) _syncTextoFromTicket(t);
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
      final t = await context.read<AuthProvider>().api.updateTicket(widget.id, {
        'titulo': titulo,
        'descripcion': _desc.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _ticket = t;
        _editingTexto = false;
      });
      _syncTextoFromTicket(t);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _savingTexto = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ticket'),
        content: Text(
          '¿Eliminar "${_ticket?.titulo ?? 'este ticket'}"?\n'
          'Se borrarán comentarios, historial y adjuntos. No se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
      await context.read<AuthProvider>().api.deleteTicket(widget.id);
      if (!mounted) return;
      context.go('/tickets');
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canManage = user?.isDesarrollador == true;
    final canDelete = user?.isLider == true;
    final wide = MediaQuery.sizeOf(context).width >= 960;

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
                    onPressed: () => context.go('/tickets'),
                    tooltip: 'Volver',
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final canEditTexto = _canEditTexto;
                    final main = [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StatusBadge.estado(_ticket!.estado),
                                PriorityIndicator(prioridad: _ticket!.prioridad),
                                if (_ticket!.sistemaAfectado.isNotEmpty)
                                  StatusBadge(
                                    label: SistemaAfectadoCatalog.labelFor(_ticket!.sistemaAfectado),
                                    color: AppColors.brand600,
                                    softColor: AppColors.slate100,
                                    showDot: false,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_editingTexto && canEditTexto) ...[
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
                                      _ticket!.titulo,
                                      style: AppTypography.textTheme.titleLarge,
                                    ),
                                  ),
                                  if (canEditTexto)
                                    IconButton(
                                      tooltip: 'Editar título y descripción',
                                      onPressed: _startEditTexto,
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _ticket!.descripcion.isEmpty ? 'Sin descripción' : _ticket!.descripcion,
                                style: AppTypography.textTheme.bodyLarge,
                              ),
                            ],
                            const SizedBox(height: 16),
                            AttachmentGallery(
                              adjuntos: _ticket!.adjuntos,
                              onAdd: _addAdjuntos,
                              onRemove: _removeAdjunto,
                              saving: _savingAdjunto,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Actualizado ${formatRelative(_ticket!.fechaActualizacion, empty: '')}'.trim(),
                              style: AppTypography.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: ComentariosPanel(
                          tipo: 'ticket',
                          refId: widget.id,
                          load: () => context.read<AuthProvider>().api.fetchComentarios('ticket', widget.id),
                          onSubmit: (c) => context.read<AuthProvider>().api.createComentario('ticket', widget.id, c),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: HistorialPanel(
                          items: _historial,
                          loading: _loadingHistorial,
                        ),
                      ),
                      if (canDelete) ...[
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Eliminar ticket',
                          icon: Icons.delete_outline,
                          variant: AppButtonVariant.danger,
                          expanded: true,
                          loading: _deleting,
                          onPressed: _deleting ? null : _confirmDelete,
                        ),
                      ],
                    ];

                    final side = AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detalles', style: AppTypography.textTheme.titleMedium),
                          const SizedBox(height: 14),
                          _DetailRow('Reportado por', _ticket!.reportadoPorNombre ?? '—'),
                          _DetailRow('Creado', formatDateTimeShort(_ticket!.fechaCreacion)),
                          _DetailRow('Atendido', formatDateTimeShort(historialHito(_historial, 'en_proceso'))),
                          _DetailRow('Resuelto', formatDateTimeShort(historialHito(_historial, 'resuelto'))),
                          _DetailRow('Cerrado', formatDateTimeShort(historialHito(_historial, 'cerrado'))),
                          if (_ticket!.proyectoTitulo != null) _DetailRow('Proyecto', _ticket!.proyectoTitulo!),
                          if (!canManage) _DetailRow('Impacto', labelPrioridad(_ticket!.impacto)),
                          if (canManage) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),

                            // ── Asignación ──────────────────────────────
                            Text('Asignado a', style: AppTypography.textTheme.labelMedium),
                            const SizedBox(height: 8),
                            if (_loadingAssignees)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: LinearProgressIndicator(minHeight: 2),
                              )
                            else
                              DropdownButtonFormField<int?>(
                                key: ValueKey(_ticket!.asignadoAId),
                                initialValue: _ticket!.asignadoAId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  hintText: 'Sin asignar',
                                  prefixIcon: Icon(Icons.person_outline),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('Sin asignar'),
                                  ),
                                  for (final u in _dropdownUsers)
                                    DropdownMenuItem<int?>(
                                      value: u.id,
                                      child: Text(u.fullName, overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: (id) => _patch({'asignado_a': id}),
                              ),
                            // Botón único: "Tomar ticket" si no asignado (avanza estado),
                            // "Asignarme" si asignado a otro, oculto si ya es mío.
                            if (user != null && _ticket!.asignadoAId != user.id) ...[
                              const SizedBox(height: 10),
                              AppButton(
                                label: _ticket!.asignadoAId == null
                                    ? 'Tomar ticket'
                                    : 'Asignarme',
                                icon: _ticket!.asignadoAId == null
                                    ? Icons.handshake_outlined
                                    : Icons.person_add_alt_1_outlined,
                                variant: _ticket!.asignadoAId == null
                                    ? AppButtonVariant.primary
                                    : AppButtonVariant.secondary,
                                expanded: true,
                                onPressed: _ticket!.asignadoAId == null
                                    ? _tomar
                                    : () => _patch({'asignado_a': user.id}),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // ── Estado ──────────────────────────────────
                            Text('Estado', style: AppTypography.textTheme.labelMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final e in ['nuevo', 'en_proceso', 'esperando', 'resuelto', 'cerrado'])
                                  ColorChip(
                                    label: labelEstado(e),
                                    selected: _ticket!.estado == e,
                                    color: estadoColor(e),
                                    softColor: estadoSoft(e),
                                    onTap: () => _patch({'estado': e}),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // ── Prioridad e Impacto en fila ─────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Prioridad', style: AppTypography.textTheme.labelMedium),
                                      const SizedBox(height: 8),
                                      for (final p in ['alta', 'media', 'baja']) ...[
                                        ColorChip(
                                          label: labelPrioridad(p),
                                          selected: _ticket!.prioridad == p,
                                          color: prioridadColor(p),
                                          softColor: prioridadSoft(p),
                                          onTap: () => _patch({'prioridad': p}),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Impacto', style: AppTypography.textTheme.labelMedium),
                                      const SizedBox(height: 8),
                                      for (final p in ['alta', 'media', 'baja']) ...[
                                        ColorChip(
                                          label: labelPrioridad(p),
                                          selected: _ticket!.impacto == p,
                                          color: impactoColor(p),
                                          softColor: impactoSoft(p),
                                          onTap: () => _patch({'impacto': p}),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            _DetailRow('Asignado a', _ticket!.asignadoANombre ?? 'Sin asignar'),
                          ],
                        ],
                      ),
                    );

                    if (wide) {
                      final maxH = constraints.hasBoundedHeight
                          ? constraints.maxHeight
                          : MediaQuery.sizeOf(context).height;
                      final bodyH = (maxH - 48).clamp(200.0, double.infinity);
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: bodyH,
                                child: ListView(
                                  children: main,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 320,
                              height: bodyH,
                              child: SingleChildScrollView(child: side),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [...main, const SizedBox(height: 16), side],
                    );
                  },
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.textTheme.titleSmall),
        ],
      ),
    );
  }
}

// ColorChip movido a lib/widgets/ui/color_chip.dart y re-exportado desde ui.dart
