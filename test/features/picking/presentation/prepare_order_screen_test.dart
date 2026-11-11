import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/prepare_order_screen.dart';

import '../../../support/button_finders.dart';

// Primer paso del preparador. La acción principal es "Escanear producto" (ver
// prepare_order_scan_test.dart); acá se prueba la alternativa: escribir el
// número de pedido y "Abrir pedido". Solo navega con algo con forma de pedido.

const _invalidMessage =
    'Ese no es un número de pedido válido (ej. DIS-123456).';

Future<void> _pump(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/picking/prepare',
    routes: [
      GoRoute(
        path: '/picking/prepare',
        builder: (_, _) => const PrepareOrderScreen(),
      ),
      GoRoute(
        path: '/picking/order/:orderNumber',
        builder: (_, state) => Scaffold(
          body: Text('ORDEN ${state.pathParameters['orderNumber']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

Finder _openButton() => findButtonWithText<OutlinedButton>('Abrir pedido');

Future<void> _typeAndOpen(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.ensureVisible(_openButton());
  await tester.tap(_openButton());
  await tester.pumpAndSettle();
}

void _expectStillOnForm() {
  expect(find.text('Preparar pedido'), findsOneWidget);
  expect(find.textContaining('ORDEN '), findsNothing);
}

void main() {
  testWidgets('escanear es la acción principal; escribir, la alternativa', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Escaneá un producto'), findsOneWidget);
    expect(
      findButtonWithText<FilledButton>('Escanear producto'),
      findsOneWidget,
    );
    expect(find.text('O escribí el número de pedido'), findsOneWidget);
    expect(find.text('Ej. DIS-123456'), findsOneWidget); // hint del campo
    expect(_openButton(), findsOneWidget);
    // Los botones viejos ya no existen.
    expect(find.text('Ver etiquetas'), findsNothing);
    expect(find.text('Escanear pedido'), findsNothing);
  });

  testWidgets('escribir y "Abrir pedido" navega al pedido (recorta espacios)', (
    tester,
  ) async {
    await _pump(tester);

    await _typeAndOpen(tester, '  DIS-123456  ');

    expect(find.text('ORDEN DIS-123456'), findsOneWidget);
  });

  testWidgets('enviar desde el teclado (onSubmitted) navega al pedido', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'DIS-999');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(find.text('ORDEN DIS-999'), findsOneWidget);
  });

  testWidgets('con el campo vacío no navega y pide el número', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(_openButton());
    await tester.tap(_openButton());
    await tester.pumpAndSettle();

    _expectStillOnForm();
    expect(find.text('Escribí el número de pedido.'), findsOneWidget);
  });

  testWidgets('solo espacios cuenta como vacío', (tester) async {
    await _pump(tester);

    await _typeAndOpen(tester, '    ');

    _expectStillOnForm();
    expect(find.text('Escribí el número de pedido.'), findsOneWidget);
  });

  testWidgets('pegar el JSON de una etiqueta muestra el aviso y no navega', (
    tester,
  ) async {
    await _pump(tester);

    await _typeAndOpen(tester, '{"v":1,"t":"PKG","o":"DM-1"}');

    _expectStillOnForm();
    expect(find.text(_invalidMessage), findsOneWidget);
  });

  testWidgets('un número con espacios internos es inválido', (tester) async {
    await _pump(tester);

    await _typeAndOpen(tester, 'DIS 123');

    _expectStillOnForm();
    expect(find.text(_invalidMessage), findsOneWidget);
  });

  testWidgets('inválido por teclado (onSubmitted) tampoco navega', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'hola mundo');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    _expectStillOnForm();
    expect(find.text(_invalidMessage), findsOneWidget);
  });

  testWidgets('al volver del pedido, el campo conserva lo escrito', (
    tester,
  ) async {
    await _pump(tester);

    await _typeAndOpen(tester, 'DIS-42');
    expect(find.text('ORDEN DIS-42'), findsOneWidget);

    GoRouter.of(tester.element(find.text('ORDEN DIS-42'))).pop();
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'DIS-42');
  });
}
