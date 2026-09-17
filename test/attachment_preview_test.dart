import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_proyectos/models/models.dart';
import 'package:gestor_proyectos/utils/attachment_files.dart';
import 'package:gestor_proyectos/widgets/ui/screenshot_picker.dart';

void main() {
  test('mimeFromFileName reconoce PDF, Word y Excel', () {
    expect(mimeFromFileName('nota.pdf'), 'application/pdf');
    expect(mimeFromFileName('spec.doc'), 'application/msword');
    expect(
      mimeFromFileName('informe.docx'),
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
    expect(mimeFromFileName('datos.xls'), 'application/vnd.ms-excel');
    expect(
      mimeFromFileName('datos.xlsx'),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    expect(mimeFromFileName('foto.png'), 'image/png');
    expect(isAllowedAttachmentName('plan.xlsx'), isTrue);
    expect(isAllowedAttachmentName('malware.exe'), isFalse);
  });

  testWidgets('muestra icono de documento para PDF', (tester) async {
    const adjunto = TicketAdjunto(
      id: '1',
      nombre: 'manual.pdf',
      url: 'https://example.com/manual.pdf',
      mimeType: 'application/pdf',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AttachmentPreview(adjunto: adjunto)),
      ),
    );

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('manual.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('muestra icono de documento para Excel', (tester) async {
    const adjunto = TicketAdjunto(
      id: '2',
      nombre: 'kits.xlsx',
      url: 'https://example.com/kits.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AttachmentPreview(adjunto: adjunto)),
      ),
    );

    expect(find.text('XLSX'), findsOneWidget);
    expect(find.text('kits.xlsx'), findsOneWidget);
    expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
  });
}
