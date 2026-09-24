import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/sistemas_catalog.dart';
import '../models/app_user.dart';
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
    this.initialBandeja,
  });

  final bool onlyAssignedToMe;
  final bool onlyUnassigned;
  final String? initialBandeja;

  @override
  State<TicketsListPage> createState() => _TicketsListPageState();
}

class _TicketsListPageState extends State<TicketsListPage> {
  List<Ticket> _items = [];
  bool _loading = true;
  String? _error;
  /// null = vista agrupada. `por_aprobar` | `nuevos` | `en_curso` | `esperando` | `mios` | `resuelto` | `rechazado` | `cerrado`
  String? _bandeja;
  String _query = '';
  int _countMine = 0;
  int _countUnassigned = 0;
  int _countPorAprobar = 0;
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
    _syncBandejaFromRoute();
    _load();
  }

  @override
  void didUpdateWidget(TicketsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onlyAssignedToMe != widget.onlyAssignedToMe ||
        oldWidget.onlyUnassigned != widget.onlyUnassigned ||
        oldWidget.initialBandeja != widget.initialBandeja) {
      _syncBandejaFromRoute();
      _load();
    }
  }

  void _syncBandejaFromRoute() {
    if (widget.onlyUnassigned) {
      _bandeja = 'nuevos';
    } else if (widget.onlyAssignedToMe) {
      _bandeja = 'mios';
    } else if (widget.initialBandeja == 'por_aprobar') {
      _bandeja = 'por_aprobar';
    }
  }

  List<Ticket> _of(String bandeja, AppUser? user) {
    switch (bandeja) {
      case 'por_aprobar':
      case 'revision':
        return _items.where((t) => t.estado == 'por_aprobar').toList();
      case 'nuevos':
        final soloCola = user?.isDesarrollador == true && user?.isLider != true;
        return _items.where((t) {
          if (t.estado != 'nuevo') return false;
          if (soloCola) return t.asignadoAId == null;
          return true;
        }).toList();
      case 'mios':
        return _items
            .where((t) =>
                t.asignadoAId == user?.id &&
                (t.estado == 'nuevo' || t.estado == 'en_proceso'))
            .toList();
      case 'esperando':
        return _items.where((t) => t.estado == 'esperando').toList();
      case 'en_curso':
        return _items
            .where((t) => t.estado == 'en_proceso' || t.estado == 'esperando')
            .toList();
      case 'resuelto':
        return _items.where((t) => t.estado == 'resuelto').toList();
      case 'rechazado':
        return _items.where((t) => t.estado == 'rechazado').toList();
      case 'cerrado':
        return _items.where((t) => t.estado == 'cerrado').toList();
      default:
        return _items;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final inbox = await auth.api.fetchInbox();
      final countMine = inbox.asignadosAMi;
      final countUnassigned = inbox.colaSinAsignar;
      final countPorAprobar = inbox.porAprobar;

      var items = await auth.api.fetchTickets();
      if (widget.onlyUnassigned) {
        items = items.where((t) => t.estado == 'nuevo' && t.asignadoAId == null).toList();
      } else if (widget.onlyAssignedToMe && auth.user != null) {
        final uid = auth.user!.id;
        items = items
            .where((t) =>
                t.asignadoAId == uid &&
                (t.estado == 'nuevo' || t.estado == 'en_proceso'))
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
          _countPorAprobar = countPorAprobar;
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
    final isLider = user?.isLider == true;
    final isRegular = !isDev;
    final listTitle = widget.onlyUnassigned
        ? 'Cola sin asignar'
        : widget.onlyAssignedToMe
            ? 'Mis pendientes'
            : 'Tickets';

    final cards = <_BandejaCard>[
      if (isDev)
        _BandejaCard('por_aprobar', 'Por aprobar', _countPorAprobar, AppColors.warning, AppColors.warningSoft)
      else if (isRegular)
        _BandejaCard('revision', 'En revisión', _of('revision', user).length, AppColors.warning, AppColors.warningSoft),
      if (isDev && !isLider) ...[
        _BandejaCard('nuevos', 'Nuevos sin asignar', _countUnassigned, AppColors.info, AppColors.infoSoft),
        _BandejaCard('mios', 'Mis pendientes', _of('mios', user).length, AppColors.brand600, AppColors.brand50),
        _BandejaCard('esperando', 'Esperando', _of('esperando', user).length, AppColors.purple, AppColors.purpleSoft),
      ] else ...[
        _BandejaCard('nuevos', 'Nuevos', _of('nuevos', user).length, AppColors.info, AppColors.infoSoft),
        _BandejaCard('en_curso', 'En curso', _of('en_curso', user).length, AppColors.warning, AppColors.warningSoft),
      ],
      _BandejaCard(
        'resuelto',
        'Resuelto',
        _of('resuelto', user).length,
        AppColors.success,
        AppColors.successSoft,
      ),
      _BandejaCard(
        'rechazado',
        'Rechazado',
        _of('rechazado', user).length,
        AppColors.danger,
        AppColors.dangerSoft,
      ),
      _BandejaCard(
        'cerrado',
        'Cerrado',
        _of('cerrado', user).length,
        AppColors.slate700,
        AppColors.slate100,
      ),
    ];

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
                  subtitle: _bandeja == null
                      ? '${_items.length} resultados'
                      : '${_of(_bandeja!, user).length} en esta bandeja',
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in cards)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _InboxTile(
                            label: c.label,
                            count: c.count,
                            color: c.color,
                            soft: c.soft,
                            selected: _bandeja == c.id,
                            onTap: () => setState(() {
                              _bandeja = _bandeja == c.id ? null : c.id;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
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
                      : _buildInbox(context, user, isLider, isRegular),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInbox(BuildContext context, AppUser? user, bool isLider, bool isRegular) {
    final sections = _bandeja == null
        ? _sectionsFor(user, isLider, isRegular)
        : [(label: _sectionTitle(_bandeja!), id: _bandeja!, tint: null as Color?)];
    final children = <Widget>[];
    for (final s in sections) {
      var items = _of(s.id, user);
      if (s.id == 'nuevos') {
        items.sort((a, b) {
          final da = a.fechaCreacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.fechaCreacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      } else {
        _applySort(items);
      }
      if (items.isEmpty && _bandeja == null) continue;
      children.add(_sectionHeader(s.label, items.length, tint: s.tint));
      if (items.isEmpty) {
        children.add(const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Nada en esta bandeja'),
        ));
      }
      for (final t in items) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ticketRow(context, t, isRegular),
        ));
      }
    }
    if (children.isEmpty) {
      return ListView(children: const [AppEmptyState(message: 'No hay tickets')]);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
      children: children,
    );
  }

  List<({String label, String id, Color? tint})> _sectionsFor(
    AppUser? user,
    bool isLider,
    bool isRegular,
  ) {
    return [
      if (!isRegular)
        (label: 'Por aprobar', id: 'por_aprobar', tint: AppColors.warningSoft)
      else if (isRegular)
        (label: 'En revisión', id: 'revision', tint: AppColors.warningSoft),
      (label: isLider || isRegular ? 'Nuevos' : 'Nuevos sin asignar', id: 'nuevos', tint: null),
      if (isLider || isRegular)
        (label: 'En curso', id: 'en_curso', tint: null)
      else ...[
        (label: 'Mis pendientes', id: 'mios', tint: null),
        (label: 'Esperando', id: 'esperando', tint: null),
      ],
      (label: 'Resuelto', id: 'resuelto', tint: null),
      (label: 'Rechazado', id: 'rechazado', tint: null),
      (label: 'Cerrado', id: 'cerrado', tint: null),
    ];
  }

  String _sectionTitle(String id) {
    switch (id) {
      case 'por_aprobar':
        return 'Por aprobar';
      case 'revision':
        return 'En revisión';
      case 'nuevos':
        return 'Nuevos';
      case 'en_curso':
        return 'En curso';
      case 'mios':
        return 'Mis pendientes';
      case 'esperando':
        return 'Esperando';
      case 'resuelto':
        return 'Resuelto';
      case 'rechazado':
        return 'Rechazado';
      case 'cerrado':
        return 'Cerrado';
      default:
        return 'Tickets';
    }
  }

  Widget _sectionHeader(String label, int count, {Color? tint, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tint ?? AppColors.slate100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label · $count',
            style: AppTypography.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(BuildContext context, Ticket t, bool isRegular) {
    final label = isRegular && t.estado == 'por_aprobar' ? 'En revisión' : labelEstado(t.estado);
    final accent = estadoColor(t.estado);
    return AppCard(
      hoverable: true,
      padding: EdgeInsets.zero,
      onTap: () => context.go('/tickets/${t.id}'),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          AppAvatar(name: t.asignadoANombre ?? 'Sin asignar', size: 28),
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
                    StatusBadge(
                      label: label,
                      color: accent,
                      softColor: estadoSoft(t.estado),
                    ),
                    const SizedBox(width: 10),
                    PriorityIndicator(prioridad: t.prioridad),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 88,
                      child: Text(
                        formatRelative(t.fechaCreacion),
                        textAlign: TextAlign.right,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          fontWeight: t.estado == 'nuevo' ? FontWeight.w700 : null,
                          color: t.estado == 'nuevo' ? AppColors.info : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandejaCard {
  const _BandejaCard(this.id, this.label, this.count, this.color, this.soft);
  final String id;
  final String label;
  final int count;
  final Color color;
  final Color soft;
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
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
          constraints: const BoxConstraints(minWidth: 148, maxWidth: 220),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppColors.slate200, width: selected ? 1.5 : 1),
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
                maxLines: 2,
                style: AppTypography.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
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

  bool _puedeAprobarTicket(AppUser user, Ticket t) {
    return t.estado == 'por_aprobar' && user.isDesarrollador;
  }

  bool _puedeRechazarTicket(AppUser user, Ticket t) {
    if (t.estado != 'por_aprobar') return false;
    if (user.isGestor) return true;
    return user.isLider && user.areaId != null && user.areaId == t.areaId;
  }

  Future<int?> _pedirAutorizacion(AppUser user) async {
    final usuarios = await context.read<AuthProvider>().api.fetchAssignableUsers();
    if (!mounted) return null;
    final autorizadores = usuarios.where((u) {
      final rol = (u.rol ?? '').toLowerCase();
      return rol.contains('líder') || rol.contains('lider') || rol.contains('gestor');
    }).toList();
    var propio = true;
    int? otroId = autorizadores.isEmpty ? null : autorizadores.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('¿Quién autoriza?'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RadioListTile<bool>(
                  value: true,
                  groupValue: propio,
                  title: const Text('Yo lo autorizo'),
                  subtitle: const Text('Cambio técnico menor'),
                  onChanged: (v) => setLocal(() => propio = v ?? true),
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue: propio,
                  title: const Text('Lo autorizó un líder o gestor'),
                  onChanged: autorizadores.isEmpty
                      ? null
                      : (v) => setLocal(() => propio = v ?? false),
                ),
                if (!propio)
                  DropdownButtonFormField<int>(
                    initialValue: otroId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Autorizó'),
                    items: [
                      for (final u in autorizadores)
                        DropdownMenuItem(
                          value: u.id,
                          child: Text(
                            '${u.fullName}${u.rol == null ? '' : ' · ${u.rol}'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => otroId = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Aprobar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    return propio ? user.id : otroId;
  }

  Future<void> _aprobar() async {
    final user = context.read<AuthProvider>().user;
    int? autorizadoPorId;
    if (user != null && !user.isLider) {
      autorizadoPorId = await _pedirAutorizacion(user);
      if (autorizadoPorId == null || !mounted) return;
    }
    try {
      final t = await context.read<AuthProvider>().api.approveTicket(
        widget.id,
        autorizadoPorId: autorizadoPorId,
      );
      if (!mounted) return;
      setState(() => _ticket = t);
      await _loadHistorial();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket aprobado. Ya está en la cola.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _rechazar() async {
    final ctrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar ticket'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Por qué no se aprueba',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (motivo == null || !mounted) return;
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El motivo es obligatorio.')),
      );
      return;
    }
    try {
      final t = await context.read<AuthProvider>().api.rejectTicket(widget.id, motivo);
      if (!mounted) return;
      setState(() => _ticket = t);
      await _loadHistorial();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
                          if (_ticket!.aprobadoPorNombre != null)
                            _DetailRow('Aprobado por', _ticket!.aprobadoPorNombre!),
                          if (_ticket!.autorizadoPorNombre != null)
                            _DetailRow('Autorizado por', _ticket!.autorizadoPorNombre!),
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

                            if (user != null &&
                                _puedeAprobarTicket(user, _ticket!)) ...[
                              Text(
                                'Este ticket espera aprobación',
                                style: AppTypography.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              AppButton(
                                label: 'Aprobar',
                                icon: Icons.check_circle_outline,
                                expanded: true,
                                onPressed: _aprobar,
                              ),
                              if (_puedeRechazarTicket(user, _ticket!)) ...[
                              const SizedBox(height: 8),
                              AppButton(
                                label: 'Rechazar',
                                icon: Icons.cancel_outlined,
                                variant: AppButtonVariant.danger,
                                expanded: true,
                                onPressed: _rechazar,
                              ),
                              ],
                              const SizedBox(height: 16),
                            ],

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
                            if (user != null &&
                                _ticket!.asignadoAId != user.id &&
                                _ticket!.estado != 'por_aprobar' &&
                                _ticket!.estado != 'rechazado') ...[
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

                            if (_ticket!.estado != 'por_aprobar') ...[
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
                            ],

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
