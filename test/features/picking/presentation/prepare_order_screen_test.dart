import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/prepare_order_screen.dart';

// Primer paso del preparador: ingresar/escribir el número de pedido. El botón
// "Escanear pedido" abre la cámara (no se prueba acá). Navegación con go_router.

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

void main() {
  testWidgets(
    'escribir y "Ver etiquetas" navega al pedido (recorta espacios)',
    (tester) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField), '  DIS-123456  ');
      await tester.tap(find.text('Ver etiquetas'));
      await tester.pumpAndSettle();

      expect(find.text('ORDEN DIS-123456'), findsOneWidget);
    },
  );

  testWidgets('enviar desde el teclado (onSubmitted) navega al pedido', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'DIS-999');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(find.text('ORDEN DIS-999'), findsOneWidget);
  });

  testWidgets('con el campo vacío "Ver etiquetas" no navega', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Ver etiquetas'));
    await tester.pumpAndSettle();

    // Sigue en la pantalla de ingreso.
    expect(find.text('Preparar pedido'), findsOneWidget);
    expect(find.textContaining('ORDEN '), findsNothing);
  });
}
