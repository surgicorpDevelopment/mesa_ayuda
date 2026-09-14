import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_proyectos/main.dart';

void main() {
  testWidgets('App arranca sin crash', (tester) async {
    await tester.pumpWidget(const GestorApp());
    await tester.pump();
    expect(find.byType(GestorApp), findsOneWidget);
  });
}
