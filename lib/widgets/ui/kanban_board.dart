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
/// - Toca el lápiz / asignado para editar título, descripción y responsable.
/// - Presiona la "×" en una tarjeta para eliminarla.
class KanbanBoard extends StatefulWidget {
  const KanbanBoard({
    super.key,
    required this.tareas,
    required this.onMove,
    required this.onCreate,
    required this.onUpdate,
    this.onDelete,
    this.usuarios = const [],
  });

  final List<Tarea> tareas;
  final void Function(Tarea tarea, String nuevoEstado) onMove;
  final void Function(
    String titulo,
    String estado,
    int? asignadoAId,
    List<TareaEspera> esperando,
  ) onCreate;

  /// Nulo cuando el usuario no puede borrar tareas: la API solo lo permite a
  /// líderes y gestores, así que sin permiso no se muestra la "×".
  final void Function(Tarea tarea)? onDelete;
  final void Function(
    Tarea tarea, {
    required String titulo,
    required String descripcion,
    required int? asignadoAId,
    required List<TareaEspera> esperando,
  }) onUpdate;
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
          onEditTap: () => _showEditDialog(tarea),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Tarea tarea) async {
    final titleCtrl = TextEditingController(text: tarea.titulo);
    final descCtrl = TextEditingController(text: tarea.descripcion);
    int? selectedUserId = tarea.asignadoAId;
    var esperando = List<TareaEspera>.from(tarea.esperando);
    final usuarios = _usuariosForDropdown(selectedUserId, tarea.asignadoANombre);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          title: const Text('Editar tarea'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(controller: titleCtrl, label: 'Título'),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: descCtrl,
                    label: 'Descripción',
                    minLines: 2,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Asignado a',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
                      for (final u in usuarios)
                        DropdownMenuItem<int?>(
                          value: u.id,
                          child: Text(u.fullName, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setStateDialog(() => selectedUserId = v),
                  ),
                  const SizedBox(height: 16),
                  _EsperandoField(
                    usuarios: usuarios,
                    value: esperando,
                    onChanged: (next) => setStateDialog(() => esperando = next),
                  ),
                ],
              ),
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
                widget.onUpdate(
                  tarea,
                  titulo: titulo,
                  descripcion: descCtrl.text.trim(),
                  asignadoAId: selectedUserId,
                  esperando: esperando,
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    titleCtrl.dispose();
    descCtrl.dispose();
  }

  List<AssignableUser> _usuariosForDropdown(int? selectedId, String? selectedName) {
    final seen = <int>{};
    final list = <AssignableUser>[];
    for (final u in widget.usuarios) {
      if (seen.add(u.id)) list.add(u);
    }
    if (selectedId != null && !seen.contains(selectedId)) {
      list.insert(
        0,
        AssignableUser(
          id: selectedId,
          fullName: selectedName ?? 'Usuario #$selectedId',
        ),
      );
    }
    return list;
  }

  Future<void> _showCreateDialog(String estado) async {
    final titleCtrl = TextEditingController();
    int? selectedUserId;
    var esperando = <TareaEspera>[];
    final usuarios = _usuariosForDropdown(null, null);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          title: const Text('Nueva tarea'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(controller: titleCtrl, label: 'Título de la tarea'),
                  if (usuarios.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedUserId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Asignar a (opcional)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
                        for (final u in usuarios)
                          DropdownMenuItem<int?>(
                            value: u.id,
                            child: Text(u.fullName, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setStateDialog(() => selectedUserId = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _EsperandoField(
                    usuarios: usuarios,
                    value: esperando,
                    onChanged: (next) => setStateDialog(() => esperando = next),
                  ),
                ],
              ),
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
                widget.onCreate(titulo, estado, selectedUserId, esperando);
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
    this.onEditTap,
  });

  final Tarea tarea;
  final Color accentColor;
  final bool isDragging;
  final VoidCallback? onDelete;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final descripcion = tarea.descripcion.trim();
    final asignado = tarea.asignadoANombre?.trim();
    final esperando = tarea.esperando;

    return Material(
      color: AppColors.white,
      elevation: isDragging ? 6 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isDragging ? null : onEditTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.slate200),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                tarea.titulo,
                                style: AppTypography.textTheme.titleSmall?.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isDragging && (onEditTap != null || onDelete != null)) ...[
                              const SizedBox(width: 4),
                              if (onEditTap != null)
                                _CardIconButton(
                                  tooltip: 'Editar',
                                  icon: Icons.edit_outlined,
                                  onTap: onEditTap!,
                                ),
                              if (onDelete != null)
                                _CardIconButton(
                                  tooltip: 'Eliminar',
                                  icon: Icons.close,
                                  onTap: onDelete!,
                                ),
                            ],
                          ],
                        ),
                        if (descripcion.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            descripcion,
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.slate500,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (asignado != null && asignado.isNotEmpty) ...[
                              AppAvatar(name: asignado, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  asignado,
                                  style: AppTypography.textTheme.bodySmall?.copyWith(
                                    color: AppColors.slate700,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 15,
                                      color: AppColors.slate500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sin asignar',
                                      style: AppTypography.textTheme.bodySmall?.copyWith(
                                        color: AppColors.slate500,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (esperando.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                            decoration: BoxDecoration(
                              color: AppColors.warningSoft.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.hourglass_top_rounded,
                                      size: 13,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Esperando · ${esperando.length}',
                                      style: AppTypography.textTheme.labelSmall?.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                for (var i = 0; i < esperando.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 5),
                                  _EsperandoCardRow(persona: esperando[i]),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: AppColors.slate500),
        ),
      ),
    );
  }
}

class _EsperandoCardRow extends StatelessWidget {
  const _EsperandoCardRow({required this.persona});

  final TareaEspera persona;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: AppAvatar(name: persona.nombre, size: 16),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: persona.nombre,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    if (persona.esExterno)
                      TextSpan(
                        text: ' · ext.',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.slate500,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (persona.detalle.isNotEmpty)
                Text(
                  persona.detalle,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.slate500,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EsperandoField extends StatefulWidget {
  const _EsperandoField({
    required this.value,
    required this.onChanged,
    required this.usuarios,
  });

  final List<TareaEspera> value;
  final ValueChanged<List<TareaEspera>> onChanged;
  final List<AssignableUser> usuarios;

  @override
  State<_EsperandoField> createState() => _EsperandoFieldState();
}

class _EsperandoFieldState extends State<_EsperandoField> {
  final _nombreLibre = TextEditingController();
  final _detalle = TextEditingController();
  int? _usuarioSeleccionado;
  String? _error;

  @override
  void dispose() {
    _nombreLibre.dispose();
    _detalle.dispose();
    super.dispose();
  }

  bool _yaEsta(String nombre) {
    final key = nombre.trim().toLowerCase();
    return widget.value.any((e) => e.nombre.toLowerCase() == key);
  }

  void _agregar() {
    final detalle = _detalle.text.trim();
    String? nombre;
    int? usuarioId;

    if (_usuarioSeleccionado != null) {
      for (final u in widget.usuarios) {
        if (u.id == _usuarioSeleccionado) {
          nombre = u.fullName;
          usuarioId = u.id;
          break;
        }
      }
    } else if (_nombreLibre.text.trim().isNotEmpty) {
      nombre = _nombreLibre.text.trim();
    }

    if (nombre == null || nombre.isEmpty) {
      setState(() => _error = 'Elige una persona del sistema o escribe un nombre.');
      return;
    }
    if (_yaEsta(nombre)) {
      setState(() => _error = 'Esa persona ya está en la lista.');
      return;
    }

    widget.onChanged([
      ...widget.value,
      TareaEspera(nombre: nombre, usuarioId: usuarioId, detalle: detalle),
    ]);
    setState(() {
      _usuarioSeleccionado = null;
      _error = null;
      _nombreLibre.clear();
      _detalle.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final usuarios = widget.usuarios;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Esperando a alguien',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'De quién dependes para avanzar y qué le pediste. Puedes agregar varias personas.',
            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 12),
          if (value.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Text(
                'Nadie en espera todavía. Completa el formulario de abajo.',
                style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.slate500),
              ),
            )
          else ...[
            Text(
              'En espera (${value.length})',
              style: AppTypography.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < value.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppAvatar(name: value[i].nombre, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value[i].esExterno ? '${value[i].nombre} · externo' : value[i].nombre,
                              style: AppTypography.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value[i].detalle.isEmpty
                                  ? 'Sin detalle de lo pedido'
                                  : value[i].detalle,
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: value[i].detalle.isEmpty
                                    ? AppColors.slate300
                                    : AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final next = List<TareaEspera>.from(value)..removeAt(i);
                          widget.onChanged(next);
                        },
                        icon: const Icon(Icons.close, size: 18, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Agregar a la lista',
                  style: AppTypography.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                _EsperandoPaso(
                  numero: '1',
                  titulo: 'Qué necesitas',
                  child: AppTextField(
                    controller: _detalle,
                    hint: 'Ej. revisar el script, confirmar stock…',
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 14),
                _EsperandoPaso(
                  numero: '2',
                  titulo: 'De quién',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (usuarios.isNotEmpty) ...[
                        DropdownButtonFormField<int?>(
                          key: ValueKey('esp-${value.length}-$_usuarioSeleccionado'),
                          initialValue: _usuarioSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Persona del sistema',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Elegir…')),
                            for (final u in usuarios)
                              if (!_yaEsta(u.fullName))
                                DropdownMenuItem<int?>(
                                  value: u.id,
                                  child: Text(u.fullName, overflow: TextOverflow.ellipsis),
                                ),
                          ],
                          onChanged: (id) => setState(() {
                            _usuarioSeleccionado = id;
                            if (id != null) _nombreLibre.clear();
                            _error = null;
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'o nombre libre',
                                  style: AppTypography.textTheme.labelSmall?.copyWith(
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),
                      ],
                      AppTextField(
                        controller: _nombreLibre,
                        hint: 'Ej. proveedor, área externa…',
                        enabled: _usuarioSeleccionado == null,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        onSubmitted: (_) => _agregar(),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _agregar,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Agregar persona'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EsperandoPaso extends StatelessWidget {
  const _EsperandoPaso({
    required this.numero,
    required this.titulo,
    required this.child,
  });

  final String numero;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.brand600,
                shape: BoxShape.circle,
              ),
              child: Text(
                numero,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: AppTypography.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
