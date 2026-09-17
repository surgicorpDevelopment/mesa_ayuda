/// Fragmento de texto plano o hipervínculo.
class LinkifySegment {
  const LinkifySegment({required this.text, this.url});

  final String text;
  /// URL absoluta (`http`/`https`) si este fragmento es un enlace.
  final String? url;

  bool get isLink => url != null;
}

final _urlRegex = RegExp(
  r'(https?:\/\/[^\s<]+)|(www\.[^\s<]+)',
  caseSensitive: false,
);

final _trailingPunctuation = RegExp(r'[.,;:!?)]+$');

/// Parte un texto en fragmentos normales y URLs clicables.
List<LinkifySegment> splitLinkifiedText(String input) {
  if (input.isEmpty) return const [];
  final out = <LinkifySegment>[];
  var start = 0;
  for (final match in _urlRegex.allMatches(input)) {
    if (match.start > start) {
      out.add(LinkifySegment(text: input.substring(start, match.start)));
    }
    final raw = match.group(0)!;
    final trimmed = raw.replaceFirst(_trailingPunctuation, '');
    final trailing = raw.substring(trimmed.length);
    if (trimmed.isNotEmpty) {
      out.add(LinkifySegment(text: trimmed, url: _toAbsoluteUrl(trimmed)));
    }
    if (trailing.isNotEmpty) {
      out.add(LinkifySegment(text: trailing));
    }
    start = match.end;
  }
  if (start < input.length) {
    out.add(LinkifySegment(text: input.substring(start)));
  }
  return out;
}

String _toAbsoluteUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.toLowerCase().startsWith('http://') ||
      trimmed.toLowerCase().startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}
