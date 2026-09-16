const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String formatRelative(DateTime? dt, {String empty = '—'}) {
  if (dt == null) return empty;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  return formatDateShort(dt);
}

String formatDateShort(DateTime? dt, {String empty = '—'}) {
  if (dt == null) return empty;
  return '${dt.day} ${_meses[dt.month - 1]} ${dt.year}';
}

String formatDateDayMonth(DateTime dt) => '${dt.day} ${_meses[dt.month - 1]}';

String formatDateTimeShort(DateTime? dt, {String empty = '—'}) {
  if (dt == null) return empty;
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${formatDateShort(dt)} $hh:$mm';
}

String formatDateRange(DateTime? inicio, DateTime? fin, {String empty = 'Sin fechas'}) {
  if (inicio == null && fin == null) return empty;
  if (inicio != null && fin != null) {
    if (inicio.year == fin.year && inicio.month == fin.month && inicio.day == fin.day) {
      return formatDateShort(inicio);
    }
    if (inicio.year == fin.year) {
      return '${formatDateDayMonth(inicio)} – ${formatDateShort(fin)}';
    }
    return '${formatDateShort(inicio)} – ${formatDateShort(fin)}';
  }
  if (inicio != null) return 'Desde ${formatDateShort(inicio)}';
  return 'Hasta ${formatDateShort(fin)}';
}
