import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/store/presentation/widgets/load_more_footer.dart';

// Pie de las listas de tienda con scroll infinito: botón, progreso y error.

Future<void> _pump(
  WidgetTester tester, {
  bool loading = false,
  bool failed = false,
  VoidCallback? onLoadMore,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LoadMoreFooter(
          loading: loading,
          failed: failed,
          onLoadMore: onLoadMore ?? () {},
          label: 'Cargar más envíos',
          loadingLabel: 'Cargando más envíos…',
          failedLabel: 'No se pudieron cargar más envíos.',
        ),
      ),
    ),
  );
  // Con `loading` hay una animación en loop (spinner): `pumpAndSettle` nunca
  // termina. Se avanza el reloj a mano (gotcha conocido del repo).
  if (loading) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('en reposo ofrece el botón para pedir más', (tester) async {
    await _pump(tester);

    expect(find.text('Cargar más envíos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('cargando muestra el progreso y esconde el botón', (
    tester,
  ) async {
    await _pump(tester, loading: true);

    expect(find.text('Cargando más envíos…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargar más envíos'), findsNothing);
  });

  testWidgets('si falló avisa y ofrece reintentar', (tester) async {
    var calls = 0;
    await _pump(tester, failed: true, onLoadMore: () => calls++);

    expect(find.text('No se pudieron cargar más envíos.'), findsOneWidget);
    expect(find.text('Cargar más envíos'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(calls, 1);
  });
}
