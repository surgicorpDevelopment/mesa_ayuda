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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  InboxStats? _stats;
  List<Ticket> _misTickets = [];
  List<Tarea> _misTareas = [];
  Map<int, String> _proyectoTitulos = {};
  String? _error;
  bool _loading = true;

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
      final auth = context.read<AuthProvider>();
      final api = auth.api;
      final userId = auth.user?.id;
      final isDev = auth.user?.isDesarrollador == true;
      final stats = await api.fetchInbox();
      final tickets = await api.fetchTickets();

      // Desarrollador: tickets abiertos asignados a mí.
      // Usuario final: incidencias que yo reporté y siguen abiertas.
      final misTickets =
          tickets.where((t) {
            final abierto = t.estado != 'resuelto' && t.estado != 'cerrado';
            if (!abierto) return false;
            if (isDev && userId != null) return t.asignadoAId == userId;
            return t.reportadoPorId == userId;
          }).toList()..sort((a, b) {
            final da =
                a.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
            final db =
                b.fechaActualizacion ?? DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });

      var misTareas = <Tarea>[];
      var titulos = <int, String>{};
      if (isDev && userId != null) {
        final allTareas = await api.fetchTareas();
        misTareas =
            allTareas
                .where(
                  (t) =>
                      t.asignadoAId == userId &&
                      (t.estado == 'pendiente' || t.estado == 'en_progreso'),
                )
                .toList()
              ..sort((a, b) {
                if (a.estado != b.estado) {
                  if (a.estado == 'en_progreso') return -1;
                  if (b.estado == 'en_progreso') return 1;
                }
                final da =
                    a.fechaActualizacion ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final db =
                    b.fechaActualizacion ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return db.compareTo(da);
              });
        if (misTareas.isNotEmpty) {
          final proyectos = await api.fetchProyectos();
          for (final p in proyectos) {
            titulos[p.id] = p.titulo;
          }
        }
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _misTickets = misTickets;
          _misTareas = misTareas;
          _proyectoTitulos = titulos;
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

  int get _tareasPendientes =>
      _misTareas.where((t) => t.estado == 'pendiente').length;
  int get _tareasEnProgreso =>
      _misTareas.where((t) => t.estado == 'en_progreso').length;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
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
                    count: _stats?.porAprobar ?? 0,
                    color: AppColors.warning,
                    onTap: () => context.go('/tickets?bandeja=por_aprobar'),
                  ),
                  _HomeTile(
                    label: 'Nuevos',
                    count: _stats?.colaSinAsignar ?? 0,
                    color: AppColors.info,
                    onTap: () => context.go('/tickets?unassigned=1'),
                  ),
                  _HomeTile(
                    label: 'Asignados a mí',
                    count: _stats?.asignadosAMi ?? 0,
                    color: AppColors.brand600,
                    onTap: () => context.go('/tickets?mine=1'),
                  ),
                  _HomeTile(
                    label: 'Tareas pendientes',
                    count: _tareasPendientes,
                    color: AppColors.info,
                    onTap: () => context.go('/tareas?estado=pendiente'),
                  ),
                  _HomeTile(
                    label: 'Tareas en progreso',
                    count: _tareasEnProgreso,
                    color: AppColors.warning,
                    onTap: () => context.go('/tareas?estado=en_progreso'),
                  ),
                ] else
                  _HomeTile(
                    label: 'Reportados por mí',
                    count: _stats?.misTicketsAbiertos ?? 0,
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
              SectionHeader(
                title: 'Mis tareas',
                subtitle: _misTareas.isEmpty
                    ? 'Avance de proyectos · nada asignado'
                    : 'Avance de proyectos · ${_misTareas.length} por avanzar',
                action: AppButton(
                  label: 'Proyectos',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.go('/proyectos'),
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
                      ? '/tickets?mine=1'
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
