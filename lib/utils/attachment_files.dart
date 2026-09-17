const kAllowedAttachmentExtensions = [
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'bmp',
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
];

const kMaxAttachmentBytes = 30 * 1024 * 1024;

String mimeFromFileName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.bmp')) return 'image/bmp';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.doc')) return 'application/msword';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

bool isAllowedAttachmentName(String name) {
  final lower = name.toLowerCase();
  return kAllowedAttachmentExtensions.any((ext) => lower.endsWith('.$ext'));
}

bool isImageAttachment({String? mimeType, required String nombre}) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime.startsWith('image/')) return true;
  final n = nombre.toLowerCase();
  return n.endsWith('.png') ||
      n.endsWith('.jpg') ||
      n.endsWith('.jpeg') ||
      n.endsWith('.gif') ||
      n.endsWith('.webp') ||
      n.endsWith('.bmp');
}

bool isPdfAttachment({String? mimeType, required String nombre}) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime == 'application/pdf') return true;
  return nombre.toLowerCase().endsWith('.pdf');
}

bool isWordAttachment({String? mimeType, required String nombre}) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime == 'application/msword' ||
      mime == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
    return true;
  }
  final n = nombre.toLowerCase();
  return n.endsWith('.doc') || n.endsWith('.docx');
}

bool isExcelAttachment({String? mimeType, required String nombre}) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime == 'application/vnd.ms-excel' ||
      mime == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
    return true;
  }
  final n = nombre.toLowerCase();
  return n.endsWith('.xls') || n.endsWith('.xlsx');
}

/// Word y Excel: el navegador no los previsualiza; se descargan.
bool isOfficeDownloadAttachment({String? mimeType, required String nombre}) {
  return isWordAttachment(mimeType: mimeType, nombre: nombre) ||
      isExcelAttachment(mimeType: mimeType, nombre: nombre);
}

String attachmentExtensionLabel(String nombre) {
  final n = nombre.toLowerCase();
  final dot = n.lastIndexOf('.');
  if (dot < 0 || dot == n.length - 1) return 'ARCHIVO';
  return n.substring(dot + 1).toUpperCase();
}
