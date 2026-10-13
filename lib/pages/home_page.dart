import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/bandeja.dart';
import '../widgets/ui/ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  InboxStats? _stats;
  List<Ticket> _misTickets = [];
  List<Tarea> _misTareas = [];
  List<CargaPersona> _equipo = [];
  Map<int, String> _proyectoTitulos = {};
  int _porAprobar = 0;
  int _colaSinAsignar = 0;
  String? _error;
  bool _loading = true;
  int? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = auth.api;
      final userId = user.id;
      final isDev = user.isDesarrollador;
      final stats = isDev ? null : await api.fetchInbox();
      final tickets = await api.fetchTickets();

      final porAprobar = tickets.where(ticketPorAprobar).length;
      final colaSinAsignar = tickets.where(ticketEnCola).length;
      final misTickets = tickets.where((t) {
        if (isDev) return ticketEnBandejaYo(t, userId);
        final abierto = t.estado != 'resuelto' &&
            t.estado != 'cerrado' &&
            t.estado != 'rechazado';
        return abierto && t.reportadoPorId == userId;
      }).toList()
        ..sort((a, b) {
          final da = a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });

      var misTareas = <Tarea>[];
      var equipo = <CargaPersona>[];
      var titulos = <int, String>{};
      if (isDev) {
        final allTareas = await api.fetchTareas();
        misTareas = allTareas.where((t) => tareaAbiertaDe(t, userId)).toList()
          ..sort((a, b) {
            if (a.estado != b.estado) {
              if (a.estado == 'en_progreso') return -1;
              if (b.estado == 'en_progreso') return 1;
            }
            final da = a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
            final db = b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
        equipo = cargasPorPersona(
          tickets: tickets,
          tareas: allTareas,
          excluirId: userId,
        );
        final proyectos = await api.fetchProyectos();
        for (final p in proyectos) {
          titulos[p.id] = p.titulo;
        }
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _misTickets = misTickets;
          _misTareas = misTareas;
          _equipo = equipo;
          _proyectoTitulos = titulos;
          _porAprobar = porAprobar;
          _colaSinAsignar = colaSinAsignar;
          _loadedForUserId = userId;
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
    if (user != null &&
        user.id != _loadedForUserId &&
        !_loading &&
        _error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && user.id != _loadedForUserId) _load();
      });
    }
    final name = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : (user?.username ?? '');
    final now = DateTime.now();
    final today = '${now.day}/${now.month}/${now.year}';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('Hola, $name', style: AppTypography.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            user?.isDesarrollador == true
                ? 'Resumen de tu bandeja · $today'
                : 'Reporta incidencias y sigue su estado · $today',
            style: AppTypography.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (_loading)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            AppCard(
              child: Column(
                children: [
                  Text(
                    _error!,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Reintentar',
                    onPressed: _load,
                    variant: AppButtonVariant.secondary,
                  ),
                ],
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user?.isDesarrollador == true) ...[
                  _HomeTile(
                    label: 'Por aprobar',
                    count: _porAprobar,
                    color: AppColors.warning,
                    onTap: () => context.go(
                      const RutaBandeja(alcance: 'cola', estado: 'por_aprobar').ticketsPath,
                    ),
                  ),
                  _HomeTile(
                    label: 'Cola sin asignar',
                    count: _colaSinAsignar,
                    color: AppColors.info,
                    onTap: () => context.go(
                      const RutaBandeja(alcance: 'cola', estado: 'sin_asignar').ticketsPath,
                    ),
                  ),
                  _HomeTile(
                    label: 'Mis tickets abiertos',
                    count: _misTickets.length,
                    color: AppColors.brand600,
                    onTap: () => context.go(const RutaBandeja(alcance: 'yo').ticketsPath),
                  ),
                  _HomeTile(
                    label: 'Mis tareas abiertas',
                    count: _misTareas.length,
                    color: AppColors.brand600,
                    onTap: () => context.go(const RutaBandeja().tareasPath),
                  ),
                ] else
                  _HomeTile(
                    label: 'Reportados por mí',
                    count: _stats?.misTicketsAbiertos ?? _misTickets.length,
                    color: AppColors.brand600,
                    onTap: () => context.go('/tickets'),
                  ),
              ],
            ).animate().fadeIn(duration: 250.ms),
            const SizedBox(height: 20),
            Row(
              children: [
                AppButton(
                  label: user?.isDesarrollador == true
                      ? 'Nuevo ticket'
                      : 'Reportar incidencia',
                  icon: Icons.add,
                  onPressed: () => context.go('/tickets/nuevo'),
                ),
                if (user?.canManageProyectos == true) ...[
                  const SizedBox(width: 10),
                  AppButton(
                    label: 'Nuevo proyecto',
                    icon: Icons.create_new_folder_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.go('/proyectos/nuevo'),
                  ),
                ],
              ],
            ),
            if (user?.isDesarrollador == true) ...[
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Equipo',
                subtitle: 'Trabajo abierto de los demás',
              ),
              const SizedBox(height: 12),
              if (_equipo.isEmpty)
                const AppEmptyState(
                  message: 'Nadie del equipo tiene trabajo abierto',
                  icon: Icons.groups_outlined,
                )
              else
                ..._equipo.asMap().entries.map((e) {
                  final p = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          AppAvatar(name: p.nombre, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _EquipoLink(
                                      label: '${p.ticketsAbiertos} tickets',
                                      onTap: () => context.go(
                                        RutaBandeja(alcance: 'persona', personaId: p.id).ticketsPath,
                                      ),
                                    ),
                                    _EquipoLink(
                                      label: '${p.tareasAbiertas} tareas',
                                      onTap: () => context.go(
                                        RutaBandeja(alcance: 'persona', personaId: p.id).tareasPath,
                                      ),
                                    ),
                                    if (p.sinMovimiento > 0)
                                      Text(
                                        'Sin movimiento · ${p.sinMovimiento}',
                                        style: AppTypography.textTheme.labelSmall?.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    if (p.enEspera > 0)
                                      Text(
                                        'En espera · ${p.enEspera}',
                                        style: AppTypography.textTheme.labelSmall?.copyWith(
                                          color: AppColors.purple,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (40 * e.key).ms);
                }),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Mis tareas',
                subtitle: _misTareas.isEmpty
                    ? 'Avance de proyectos · nada asignado'
                    : 'Avance de proyectos · ${_misTareas.length} por avanzar',
                action: AppButton(
                  label: 'Ver todas',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.go(const RutaBandeja().tareasPath),
                ),
              ),
              const SizedBox(height: 12),
              if (_misTareas.isEmpty)
                const AppEmptyState(
                  message: 'No tienes tareas de proyecto pendientes',
                  icon: Icons.task_alt_rounded,
                )
              else
                ..._misTareas.asMap().entries.map((e) {
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
                      onTap: () => context.go('/proyectos/${t.proyectoId}'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.titulo,
                                  style: AppTypography.textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  proyecto ?? 'Proyecto #${t.proyectoId}',
                                  style: AppTypography.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (etiquetaEspera(t) != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    etiquetaEspera(t)!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.textTheme.labelSmall?.copyWith(
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (tareaSinMovimiento(t)) ...[
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
                    ),
                  ).animate().fadeIn(delay: (40 * e.key).ms);
                }),
            ],
            const SizedBox(height: 28),
            SectionHeader(
              title: user?.isDesarrollador == true
                  ? 'Mis tickets pendientes'
                  : 'Mis incidencias abiertas',
              subtitle: user?.isDesarrollador == true
                  ? (_misTickets.isEmpty
                        ? 'Incidencias asignadas a ti · ninguna'
                        : 'Incidencias asignadas a ti · ${_misTickets.length}')
                  : (_misTickets.isEmpty
                        ? 'Las que reportaste y siguen abiertas'
                        : '${_misTickets.length} abiertas'),
              action: AppButton(
                label: 'Ver todos',
                variant: AppButtonVariant.ghost,
                onPressed: () => context.go(
                  user?.isDesarrollador == true
                      ? const RutaBandeja(alcance: 'yo').ticketsPath
                      : '/tickets',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_misTickets.isEmpty)
              AppEmptyState(
                message: user?.isDesarrollador == true
                    ? 'No tienes tickets pendientes asignados'
                    : 'No tienes incidencias abiertas',
                icon: Icons.confirmation_number_outlined,
              )
            else
              ..._misTickets.asMap().entries.map((e) {
                final t = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    hoverable: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    onTap: () => context.go('/tickets/${t.id}'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.titulo,
                                style: AppTypography.textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(() {
                                final parts = <String>[
                                  if (t.sistemaAfectado.isNotEmpty)
                                    t.sistemaAfectado,
                                  if (t.proyectoTitulo != null &&
                                      t.proyectoTitulo!.isNotEmpty)
                                    t.proyectoTitulo!,
                                ];
                                return parts.isEmpty
                                    ? 'Sin sistema'
                                    : parts.join(' · ');
                              }(), style: AppTypography.textTheme.bodySmall),
                              const SizedBox(height: 2),
                              Text(
                                'Reportó ${t.reportadoPorNombre ?? '—'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.bodySmall,
                              ),
                              if (user?.isDesarrollador == true && ticketSinMovimiento(t)) ...[
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
                  ),
                ).animate().fadeIn(delay: (40 * e.key).ms);
              }),
          ],
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quiet = count == 0;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 148, maxWidth: 220),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: quiet ? AppColors.slate300 : color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: quiet ? AppColors.slate300 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipoLink extends StatelessWidget {
  const _EquipoLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: AppColors.brand600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
