import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class ScreenshotPicker extends StatelessWidget {
  const ScreenshotPicker({
    super.key,
    required this.adjuntos,
    required this.onChanged,
    this.maxFiles = 5,
  });

  final List<TicketAdjunto> adjuntos;
  final ValueChanged<List<TicketAdjunto>> onChanged;
  final int maxFiles;

  Future<void> _pick(BuildContext context) async {
    if (adjuntos.length >= maxFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo $maxFiles capturas por ticket')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final next = List<TicketAdjunto>.from(adjuntos);
    for (final f in result.files) {
      if (next.length >= maxFiles) break;
      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final mime = _mimeFromName(f.name);
      final b64 = base64Encode(bytes);
      next.add(
        TicketAdjunto(
          id: 'local_${DateTime.now().microsecondsSinceEpoch}_${next.length}',
          nombre: f.name,
          mimeType: mime,
          sizeBytes: bytes.length,
          url: 'data:$mime;base64,$b64',
        ),
      );
    }
    onChanged(next);
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _remove(int index) {
    final next = List<TicketAdjunto>.from(adjuntos)..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capturas de pantalla', style: AppTypography.textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          'Adjunta hasta $maxFiles imágenes (PNG, JPG).',
          style: AppTypography.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.slate300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.brand600),
                ),
                const SizedBox(height: 10),
                Text(
                  'Haz clic para subir capturas',
                  style: AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.brand600),
                ),
                const SizedBox(height: 4),
                Text(
                  'o arrastra archivos aquí (en desktop)',
                  style: AppTypography.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (adjuntos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < adjuntos.length; i++)
                _Thumb(
                  adjunto: adjuntos[i],
                  onRemove: () => _remove(i),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.adjunto, required this.onRemove});

  final TicketAdjunto adjunto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
            color: AppColors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: AttachmentImage(url: adjunto.url, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: AppColors.danger,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Galería de adjuntos.
///
/// Modo solo lectura (por defecto): muestra miniaturas clicables.
/// Modo editable: pasa [onAdd] y/o [onRemove] para activar el botón "+"
/// y la "×" sobre cada imagen.
class AttachmentGallery extends StatelessWidget {
  const AttachmentGallery({
    super.key,
    required this.adjuntos,
    this.onAdd,
    this.onRemove,
    this.maxFiles = 5,
    this.saving = false,
  });

  final List<TicketAdjunto> adjuntos;

  /// Callback con los nuevos adjuntos seleccionados (ya listos para subir).
  final Future<void> Function(List<TicketAdjunto> nuevos)? onAdd;

  /// Callback para eliminar un adjunto existente.
  final Future<void> Function(TicketAdjunto a)? onRemove;

  final int maxFiles;

  /// Muestra un indicador de carga sobre el botón "+" cuando es true.
  final bool saving;

  bool get _editable => onAdd != null || onRemove != null;

  Future<void> _pick(BuildContext context) async {
    if (adjuntos.length >= maxFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo $maxFiles capturas por ticket')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final nuevos = <TicketAdjunto>[];
    for (final f in result.files) {
      if (adjuntos.length + nuevos.length >= maxFiles) break;
      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final mime = _mimeFromName(f.name);
      nuevos.add(TicketAdjunto(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}_${nuevos.length}',
        nombre: f.name,
        mimeType: mime,
        sizeBytes: bytes.length,
        url: 'data:$mime;base64,${base64Encode(bytes)}',
      ));
    }
    if (nuevos.isNotEmpty) await onAdd?.call(nuevos);
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _open(BuildContext context, TicketAdjunto a) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: AttachmentImage(url: a.url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Text(
                a.nombre,
                style: const TextStyle(color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _editable && adjuntos.length < maxFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Capturas adjuntas', style: AppTypography.textTheme.titleSmall),
            if (_editable) ...[
              const SizedBox(width: 6),
              Text(
                '(${adjuntos.length}/$maxFiles)',
                style: AppTypography.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (adjuntos.isEmpty && !_editable)
          Text('Sin capturas adjuntas', style: AppTypography.textTheme.bodySmall)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Miniaturas existentes
              for (final a in adjuntos)
                _GalleryThumb(
                  adjunto: a,
                  onOpen: () => _open(context, a),
                  onRemove: onRemove != null ? () => onRemove!(a) : null,
                ),
              // Botón "+" para añadir
              if (canAdd)
                _AddThumb(
                  saving: saving,
                  onTap: () => _pick(context),
                ),
            ],
          ),
      ],
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({required this.adjunto, required this.onOpen, this.onRemove});

  final TicketAdjunto adjunto;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
            ),
            clipBehavior: Clip.antiAlias,
            child: AttachmentImage(url: adjunto.url, fit: BoxFit.cover),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: AppColors.danger,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddThumb extends StatelessWidget {
  const _AddThumb({required this.onTap, required this.saving});

  final VoidCallback onTap;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: saving ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.brand500,
            style: BorderStyle.solid,
          ),
          color: AppColors.brand50,
        ),
        child: saving
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.brand600, size: 28),
                  SizedBox(height: 4),
                  Text('Agregar', style: TextStyle(fontSize: 11, color: AppColors.brand600)),
                ],
              ),
      ),
    );
  }
}

/// Renderiza data URLs (mock) o URLs remotas.
class AttachmentImage extends StatelessWidget {
  const AttachmentImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(url.substring(comma + 1));
          return Image.memory(
            bytes,
            fit: fit,
            errorBuilder: (_, __, ___) => const _BrokenImage(),
          );
        } catch (_) {
          return const _BrokenImage();
        }
      }
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => const _BrokenImage(),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.slate100,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.slate500),
      ),
    );
  }
}

/// Helper para convertir bytes a data URL (tests / mock).
String bytesToDataUrl(Uint8List bytes, {String mime = 'image/png'}) {
  return 'data:$mime;base64,${base64Encode(bytes)}';
}
