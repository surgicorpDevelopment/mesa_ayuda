import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

Future<bool> openBytesAsFile({
  required Uint8List bytes,
  required String mimeType,
  required String filename,
}) async {
  // Fuera de web no hay Blob; intentar data URL solo si es pequeño.
  if (bytes.length > 1.5 * 1024 * 1024) return false;
  final b64 = Uri.dataFromBytes(bytes, mimeType: mimeType);
  return launchUrl(b64, mode: LaunchMode.externalApplication);
}

Future<bool> openRemoteUrl(String url) async {
  final uri = Uri.parse(url);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> downloadRemoteFile({
  required String url,
  required String mimeType,
  required String filename,
}) async {
  return openRemoteUrl(url);
}
