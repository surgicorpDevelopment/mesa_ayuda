import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_proyectos/main.dart';

void main() {
  testWidgets('App arranca sin crash', (tester) async {
    await tester.pumpWidget(const GestorApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(GestorApp), findsOneWidget);
  });
}
