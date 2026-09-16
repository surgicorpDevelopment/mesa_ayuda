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
            width: 400,
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Container(
            width: 3,
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
                ),
                if (tarea.descripcion.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tarea.descripcion,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.slate500,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                if (!isDragging && onEditTap != null)
                  InkWell(
                    onTap: onEditTap,
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
                              'Editar',
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
                if (tarea.esperando.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 13, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Esperando',
                              style: AppTypography.textTheme.labelSmall?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final p in tarea.esperando)
                              Container(
                                padding: const EdgeInsets.fromLTRB(7, 4, 7, 5),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.esExterno ? '${p.nombre} (ext.)' : p.nombre,
                                      style: AppTypography.textTheme.labelSmall?.copyWith(
                                        color: AppColors.slate700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (p.detalle.isNotEmpty)
                                      Text(
                                        p.detalle,
                                        style: AppTypography.textTheme.labelSmall?.copyWith(
                                          color: AppColors.slate500,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
      ),
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

  void _add({required String nombre, int? usuarioId}) {
    final n = nombre.trim();
    if (n.isEmpty || _yaEsta(n)) return;
    widget.onChanged([
      ...widget.value,
      TareaEspera(nombre: n, usuarioId: usuarioId, detalle: _detalle.text.trim()),
    ]);
    _nombreLibre.clear();
    _detalle.clear();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final usuarios = widget.usuarios;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Esperando a', style: AppTypography.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          'Quién y qué necesitas para seguir (sin límite de personas).',
          style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.slate500),
        ),
        const SizedBox(height: 8),
        if (value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                for (var i = 0; i < value.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InputChip(
                      isEnabled: true,
                      label: SizedBox(
                        width: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value[i].esExterno ? '${value[i].nombre} (ext.)' : value[i].nombre,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (value[i].detalle.isNotEmpty)
                              Text(
                                value[i].detalle,
                                style: TextStyle(fontSize: 11, color: AppColors.slate500),
                              ),
                          ],
                        ),
                      ),
                      onDeleted: () {
                        final next = List<TareaEspera>.from(value)..removeAt(i);
                        widget.onChanged(next);
                      },
                    ),
                  ),
              ],
            ),
          ),
        AppTextField(
          controller: _detalle,
          label: 'Qué necesito',
          hint: 'Ej. revisar el script, confirmar stock…',
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        if (usuarios.isNotEmpty)
          DropdownButtonFormField<int?>(
            key: ValueKey(value.map((e) => e.nombre).join('|')),
            initialValue: null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Agregar del sistema',
              prefixIcon: Icon(Icons.group_add_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Elegir persona…')),
              for (final u in usuarios)
                if (!_yaEsta(u.fullName))
                  DropdownMenuItem<int?>(
                    value: u.id,
                    child: Text(u.fullName, overflow: TextOverflow.ellipsis),
                  ),
            ],
            onChanged: (id) {
              if (id == null) return;
              AssignableUser? u;
              for (final x in usuarios) {
                if (x.id == id) {
                  u = x;
                  break;
                }
              }
              if (u == null) return;
              _add(nombre: u.fullName, usuarioId: u.id);
            },
          ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppTextField(
                controller: _nombreLibre,
                label: 'Nombre libre',
                hint: 'Quien no está en el sistema',
                onSubmitted: (_) => _add(nombre: _nombreLibre.text),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: IconButton.filled(
                tooltip: 'Agregar',
                onPressed: () => _add(nombre: _nombreLibre.text),
                icon: const Icon(Icons.add, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
