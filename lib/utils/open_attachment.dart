import 'dart:convert';
import 'dart:typed_data';

import '../models/models.dart';
import 'attachment_files.dart';
import 'open_attachment_io.dart'
    if (dart.library.html) 'open_attachment_web.dart' as platform;

/// Abre o descarga un adjunto.
/// En web, las data URLs no se navegan (Chrome las deja en blanco);
/// se convierten a Blob URL.
Future<bool> openAttachment(TicketAdjunto adjunto) async {
  final raw = adjunto.url.trim();
  if (raw.isEmpty) return false;

  final mime = (adjunto.mimeType != null && adjunto.mimeType!.isNotEmpty)
      ? adjunto.mimeType!
      : mimeFromFileName(adjunto.nombre);

  if (raw.startsWith('data:')) {
    final bytes = _bytesFromDataUrl(raw);
    if (bytes == null || bytes.isEmpty) return false;
    return platform.openBytesAsFile(
      bytes: bytes,
      mimeType: mime,
      filename: adjunto.nombre,
    );
  }

  try {
    final uri = Uri.parse(raw);
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    // Word/Excel: forzar descarga; PDF/imágenes: abrir en pestaña.
    if (isOfficeDownloadAttachment(mimeType: mime, nombre: adjunto.nombre)) {
      return await platform.downloadRemoteFile(
        url: raw,
        mimeType: mime,
        filename: adjunto.nombre,
      );
    }
    return await platform.openRemoteUrl(raw);
  } catch (_) {
    return false;
  }
}

Uint8List? _bytesFromDataUrl(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(dataUrl.substring(comma + 1));
  } catch (_) {
    return null;
  }
}
