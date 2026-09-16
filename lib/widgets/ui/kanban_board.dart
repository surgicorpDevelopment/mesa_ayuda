import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_avatar.dart';
import 'app_text_field.dart';

/// Definición de una columna del tablero Kanban.
class _ColumnDef {
  const _ColumnDef(this.estado, this.label, this.color, this.softColor);

  final String estado;
  final String label;
  final Color color;
  final Color softColor;
}

/// Tablero Kanban de 3 columnas (Pendiente / En progreso / Hecho) para las
/// [Tarea]s de un proyecto.
///
/// - Arrastra una tarjeta hacia otra columna para cambiar su estado.
/// - Presiona "+" en cualquier columna para crear una tarea rápida.
/// - Toca el asignado (o "Asignar") para cambiar el responsable.
/// - Presiona la "×" en una tarjeta para eliminarla.
class KanbanBoard extends StatefulWidget {
  const KanbanBoard({
    super.key,
    required this.tareas,
    required this.onMove,
    required this.onCreate,
    required this.onAssign,
    this.onDelete,
    this.usuarios = const [],
  });

  final List<Tarea> tareas;
  final void Function(Tarea tarea, String nuevoEstado) onMove;
  final void Function(String titulo, String estado, int? asignadoAId) onCreate;

  /// Nulo cuando el usuario no puede borrar tareas: la API solo lo permite a
  /// líderes y gestores, así que sin permiso no se muestra la "×".
  final void Function(Tarea tarea)? onDelete;
  final void Function(Tarea tarea, int? asignadoAId) onAssign;
  final List<AssignableUser> usuarios;

  static const _kColumns = [
    _ColumnDef('pendiente',   'Pendiente',   AppColors.info,    AppColors.infoSoft),
    _ColumnDef('en_progreso', 'En progreso', AppColors.warning,  AppColors.warningSoft),
    _ColumnDef('hecho',       'Hecho',       AppColors.success,  AppColors.successSoft),
  ];

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  String? _draggingOverColumn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < KanbanBoard._kColumns.length; i++) ...[
            Expanded(child: _buildColumn(KanbanBoard._kColumns[i])),
            if (i < KanbanBoard._kColumns.length - 1)
              const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildColumn(_ColumnDef col) {
    final tareas = widget.tareas.where((t) => t.estado == col.estado).toList();
    final isTarget = _draggingOverColumn == col.estado;

    return DragTarget<Tarea>(
      onWillAcceptWithDetails: (details) {
        if (details.data.estado == col.estado) return false;
        setState(() => _draggingOverColumn = col.estado);
        return true;
      },
      onLeave: (_) => setState(() => _draggingOverColumn = null),
      onAcceptWithDetails: (details) {
        setState(() => _draggingOverColumn = null);
        if (details.data.estado != col.estado) {
          widget.onMove(details.data, col.estado);
        }
      },
      builder: (ctx, candidates, rejected) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isTarget ? col.softColor : AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTarget ? col.color : AppColors.slate200,
              width: isTarget ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Encabezado ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: col.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        col.label,
                        style: AppTypography.textTheme.labelMedium?.copyWith(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: col.softColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tareas.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: col.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.slate200),
              // ── Tarjetas ─────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  itemCount: tareas.length,
                  itemBuilder: (ctx, i) => _buildCard(tareas[i], col),
                ),
              ),
              // ── Botón agregar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                child: TextButton.icon(
                  onPressed: () => _showCreateDialog(col.estado),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Agregar tarea'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.slate500,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    textStyle: AppTypography.textTheme.labelSmall,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(Tarea tarea, _ColumnDef col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Draggable<Tarea>(
        data: tarea,
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 256,
            child: _TareaCardContent(
              tarea: tarea,
              accentColor: col.color,
              isDragging: true,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _TareaCardContent(
            tarea: tarea,
            accentColor: col.color,
            isDragging: false,
          ),
        ),
        child: _TareaCardContent(
          tarea: tarea,
          accentColor: col.color,
          isDragging: false,
          onDelete: widget.onDelete == null ? null : () => widget.onDelete!(tarea),
          onAssignTap: () => _showAssignDialog(tarea),
        ),
      ),
    );
  }

  Future<void> _showAssignDialog(Tarea tarea) async {
    int? selectedUserId = tarea.asignadoAId;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          title: const Text('Cambiar responsable'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.titulo,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
                  initialValue: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Asignado a',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
                    for (final u in widget.usuarios)
                      DropdownMenuItem<int?>(value: u.id, child: Text(u.fullName)),
                  ],
                  onChanged: (v) => setStateDialog(() => selectedUserId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (selectedUserId != tarea.asignadoAId) {
                  widget.onAssign(tarea, selectedUserId);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(String estado) async {
    final titleCtrl = TextEditingController();
    int? selectedUserId;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          title: const Text('Nueva tarea'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: titleCtrl, label: 'Título de la tarea'),
                if (widget.usuarios.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Asignar a (opcional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
                      for (final u in widget.usuarios)
                        DropdownMenuItem<int?>(value: u.id, child: Text(u.fullName)),
                    ],
                    onChanged: (v) => setStateDialog(() => selectedUserId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final titulo = titleCtrl.text.trim();
                if (titulo.isEmpty) return;
                Navigator.of(ctx).pop();
                widget.onCreate(titulo, estado, selectedUserId);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    titleCtrl.dispose();
  }
}

/// Contenido visual de una tarjeta de tarea.
class _TareaCardContent extends StatelessWidget {
  const _TareaCardContent({
    required this.tarea,
    required this.accentColor,
    required this.isDragging,
    this.onDelete,
    this.onAssignTap,
  });

  final Tarea tarea;
  final Color accentColor;
  final bool isDragging;
  final VoidCallback? onDelete;
  final VoidCallback? onAssignTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.titulo,
                  style: AppTypography.textTheme.titleSmall?.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (!isDragging && onAssignTap != null)
                  InkWell(
                    onTap: onAssignTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          if (tarea.asignadoANombre != null) ...[
                            AppAvatar(name: tarea.asignadoANombre!, size: 17),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                tarea.asignadoANombre!,
                                style: AppTypography.textTheme.bodySmall?.copyWith(
                                  color: AppColors.slate500,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            Icon(Icons.person_add_alt_1_outlined, size: 14, color: AppColors.brand600),
                            const SizedBox(width: 4),
                            Text(
                              'Asignar',
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: AppColors.brand600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(width: 2),
                          const Icon(Icons.edit_outlined, size: 12, color: AppColors.slate300),
                        ],
                      ),
                    ),
                  )
                else if (tarea.asignadoANombre != null)
                  Row(
                    children: [
                      AppAvatar(name: tarea.asignadoANombre!, size: 17),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          tarea.asignadoANombre!,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.slate500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (onDelete != null && !isDragging)
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 2, 0),
                child: Icon(Icons.close, size: 14, color: AppColors.slate300),
              ),
            ),
        ],
      ),
    );
  }
}
