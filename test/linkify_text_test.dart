import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_proyectos/utils/linkify_text.dart';

void main() {
  test('detecta https y deja el resto del comentario', () {
    const text =
        'Adjunto link: https://1drv.ms/x/c/abc?e=bMDduk para revisar';
    final parts = splitLinkifiedText(text);
    expect(parts.length, 3);
    expect(parts[0].text, 'Adjunto link: ');
    expect(parts[0].isLink, isFalse);
    expect(parts[1].text, 'https://1drv.ms/x/c/abc?e=bMDduk');
    expect(parts[1].url, 'https://1drv.ms/x/c/abc?e=bMDduk');
    expect(parts[2].text, ' para revisar');
  });

  test('antepone https a www y recorta puntuación final', () {
    final parts = splitLinkifiedText('Ver www.surgicorp.com.');
    expect(parts.length, 3);
    expect(parts[0].text, 'Ver ');
    expect(parts[1].text, 'www.surgicorp.com');
    expect(parts[1].url, 'https://www.surgicorp.com');
    expect(parts[2].text, '.');
  });

  test('texto sin url queda en un solo fragmento', () {
    final parts = splitLinkifiedText('Sin enlaces aquí');
    expect(parts, hasLength(1));
    expect(parts.first.isLink, isFalse);
  });
}
