import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/attachment_files.dart';
import '../../utils/open_attachment.dart';

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
        SnackBar(content: Text('Máximo $maxFiles adjuntos por ticket')),
      );
      return;
    }
    final picked = await pickAttachmentFiles(
      context,
      remaining: maxFiles - adjuntos.length,
    );
    if (picked.isEmpty) return;
    onChanged([...adjuntos, ...picked]);
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
        Text('Adjuntos', style: AppTypography.textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          'Hasta $maxFiles archivos: imágenes, PDF, Word o Excel.',
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
                  child: const Icon(Icons.attach_file, color: AppColors.brand600),
                ),
                const SizedBox(height: 10),
                Text(
                  'Haz clic para subir archivos',
                  style: AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.brand600),
                ),
                const SizedBox(height: 4),
                Text(
                  'PNG, JPG, PDF, Word o Excel',
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
          child: InkWell(
            onTap: () => previewOrOpenAttachment(context, adjunto),
            child: AttachmentPreview(adjunto: adjunto, fit: BoxFit.cover),
          ),
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
/// y la "×" sobre cada archivo.
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
        SnackBar(content: Text('Máximo $maxFiles adjuntos')),
      );
      return;
    }
    final nuevos = await pickAttachmentFiles(
      context,
      remaining: maxFiles - adjuntos.length,
    );
    if (nuevos.isNotEmpty) await onAdd?.call(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _editable && adjuntos.length < maxFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Adjuntos', style: AppTypography.textTheme.titleSmall),
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
          Text('Sin adjuntos', style: AppTypography.textTheme.bodySmall)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in adjuntos)
                _GalleryThumb(
                  adjunto: a,
                  onOpen: () => previewOrOpenAttachment(context, a),
                  onRemove: onRemove != null ? () => onRemove!(a) : null,
                ),
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
            child: AttachmentPreview(adjunto: adjunto, fit: BoxFit.cover),
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
                  Icon(Icons.attach_file, color: AppColors.brand600, size: 28),
                  SizedBox(height: 4),
                  Text('Agregar', style: TextStyle(fontSize: 11, color: AppColors.brand600)),
                ],
              ),
      ),
    );
  }
}

/// Miniatura de imagen o icono de documento según el tipo.
class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    super.key,
    required this.adjunto,
    this.fit = BoxFit.cover,
  });

  final TicketAdjunto adjunto;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (isImageAttachment(mimeType: adjunto.mimeType, nombre: adjunto.nombre)) {
      return AttachmentImage(url: adjunto.url, fit: fit);
    }
    return _DocumentTile(adjunto: adjunto);
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.adjunto});

  final TicketAdjunto adjunto;

  @override
  Widget build(BuildContext context) {
    final pdf = isPdfAttachment(mimeType: adjunto.mimeType, nombre: adjunto.nombre);
    final word = isWordAttachment(mimeType: adjunto.mimeType, nombre: adjunto.nombre);
    final excel = isExcelAttachment(mimeType: adjunto.mimeType, nombre: adjunto.nombre);
    final color = pdf
        ? AppColors.danger
        : excel
            ? AppColors.success
            : word
                ? AppColors.brand600
                : AppColors.slate700;
    final bg = pdf
        ? AppColors.dangerSoft
        : excel
            ? AppColors.successSoft
            : word
                ? AppColors.brand50
                : AppColors.slate100;
    final icon = pdf
        ? Icons.picture_as_pdf_outlined
        : excel
            ? Icons.table_chart_outlined
            : word
                ? Icons.description_outlined
                : Icons.insert_drive_file_outlined;

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              attachmentExtensionLabel(adjunto.nombre),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              adjunto.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: AppColors.slate700),
            ),
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

Future<List<TicketAdjunto>> pickAttachmentFiles(
  BuildContext context, {
  required int remaining,
}) async {
  if (remaining <= 0) return const [];
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: kAllowedAttachmentExtensions,
    allowMultiple: true,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return const [];

  final nuevos = <TicketAdjunto>[];
  var skippedType = false;
  var skippedSize = false;
  for (final f in result.files) {
    if (nuevos.length >= remaining) break;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) continue;
    if (!isAllowedAttachmentName(f.name)) {
      skippedType = true;
      continue;
    }
    if (bytes.length > kMaxAttachmentBytes) {
      skippedSize = true;
      continue;
    }
    final mime = mimeFromFileName(f.name);
    nuevos.add(
      TicketAdjunto(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}_${nuevos.length}',
        nombre: f.name,
        mimeType: mime,
        sizeBytes: bytes.length,
        url: 'data:$mime;base64,${base64Encode(bytes)}',
      ),
    );
  }

  if (!context.mounted) return nuevos;
  if (skippedType) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Algunos archivos no son compatibles (PNG, JPG, PDF, Word o Excel).'),
      ),
    );
  } else if (skippedSize) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Algunos archivos superan el límite de 30 MB.')),
    );
  }
  return nuevos;
}

Future<void> previewOrOpenAttachment(BuildContext context, TicketAdjunto a) async {
  if (isImageAttachment(mimeType: a.mimeType, nombre: a.nombre)) {
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
    return;
  }

  final opened = await openAttachment(a);
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('No se pudo abrir ${a.nombre}')),
  );
}
