import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/linkify_text.dart';

/// Texto seleccionable que convierte URLs en hipervínculos.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant LinkifiedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.scheme != 'http' && uri.scheme != 'https') return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final style = widget.style;
    final linkStyle = (style ?? const TextStyle()).copyWith(
      color: AppColors.brand600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.brand600,
      fontWeight: FontWeight.w600,
    );

    final spans = <InlineSpan>[];
    for (final part in splitLinkifiedText(widget.text)) {
      if (!part.isLink) {
        spans.add(TextSpan(text: part.text));
        continue;
      }
      final recognizer = TapGestureRecognizer()..onTap = () => _open(part.url!);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: part.text,
          style: linkStyle,
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(style: style, children: spans),
    );
  }
}
