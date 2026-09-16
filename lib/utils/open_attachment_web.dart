import 'dart:js_interop';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

Future<bool> openBytesAsFile({
  required Uint8List bytes,
  required String mimeType,
  required String filename,
}) async {
  final parts = [bytes.toJS].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: mimeType),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  try {
    if (mimeType == 'application/pdf' || mimeType.startsWith('image/')) {
      final opened = web.window.open(objectUrl, '_blank');
      // Popup bloqueado → descarga
      if (opened == null) {
        _triggerDownload(objectUrl, filename);
      }
    } else {
      _triggerDownload(objectUrl, filename);
    }
    Future<void>.delayed(const Duration(minutes: 2), () {
      web.URL.revokeObjectURL(objectUrl);
    });
    return true;
  } catch (_) {
    web.URL.revokeObjectURL(objectUrl);
    return false;
  }
}

Future<bool> openRemoteUrl(String url) async {
  final opened = web.window.open(url, '_blank');
  return opened != null;
}

Future<bool> downloadRemoteFile({
  required String url,
  required String mimeType,
  required String filename,
}) async {
  try {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode >= 400) {
      return await openRemoteUrl(url);
    }
    return await openBytesAsFile(
      bytes: res.bodyBytes,
      mimeType: mimeType.isNotEmpty ? mimeType : 'application/octet-stream',
      filename: filename,
    );
  } catch (_) {
    return await openRemoteUrl(url);
  }
}

void _triggerDownload(String objectUrl, String filename) {
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = filename
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
