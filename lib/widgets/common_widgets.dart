import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'ui/section_header.dart';
import 'ui/status_badge.dart';

/// Compat layer: pantallas antiguas pueden seguir importando common_widgets.
@Deprecated('Usa StatusBadge / AppEmptyState desde widgets/ui')
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: label, color: color);
  }
}

@Deprecated('Usa AppEmptyState desde widgets/ui')
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(message: message, icon: icon);
  }
}

class ComentariosPanel extends StatefulWidget {
  const ComentariosPanel({
    super.key,
    required this.tipo,
    required this.refId,
    required this.load,
    required this.onSubmit,
  });

  final String tipo;
  final int refId;
  final Future<List<dynamic>> Function() load;
  final Future<void> Function(String cuerpo) onSubmit;

  @override
  State<ComentariosPanel> createState() => _ComentariosPanelState();
}

class _ComentariosPanelState extends State<ComentariosPanel> {
  final _controller = TextEditingController();
  List<dynamic> _items = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final items = await widget.load();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.onSubmit(text);
      _controller.clear();
      await _reload();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _relative(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Comentarios'),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_items.isEmpty)
          Text(
            'Sin comentarios aún.',
            style: AppTypography.textTheme.bodySmall,
          )
        else
          ..._items.map((c) {
            final autor = (c.autorNombre as String?) ?? 'Usuario';
            final cuerpo = c.cuerpo as String;
            final fecha = c.fechaCreacion as DateTime?;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(autor, style: AppTypography.textTheme.labelMedium),
                      const Spacer(),
                      Text(_relative(fecha), style: AppTypography.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(cuerpo, style: AppTypography.textTheme.bodyMedium),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Escribe un comentario…'),
                minLines: 1,
                maxLines: 3,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.navy900,
                foregroundColor: Colors.white,
              ),
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
