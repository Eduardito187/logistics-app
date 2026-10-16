import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/widgets/async_value_view.dart';
import 'package:logistics_app/core/widgets/empty_state.dart';

// AsyncValueView unifica loading/data/error. En error mapea ApiException a su
// mensaje y ofrece "Reintentar" solo si hay onRetry.

Future<void> _pump(
  WidgetTester tester,
  AsyncValue<String> value, {
  VoidCallback? onRetry,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AsyncValueView<String>(
          value: value,
          onRetry: onRetry,
          data: (d) => Text('DATO: $d'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('loading: muestra el spinner', (tester) async {
    await _pump(tester, const AsyncLoading<String>());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('data: muestra el widget construido con el dato', (tester) async {
    await _pump(tester, const AsyncData<String>('hola'));
    expect(find.text('DATO: hola'), findsOneWidget);
  });

  testWidgets('error ApiException: usa su .message en el EmptyState', (
    tester,
  ) async {
    const error = ApiException(status: 403, title: 'Sin permiso');
    await _pump(tester, const AsyncError<String>(error, StackTrace.empty));

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('No tenés permiso para esta acción.'), findsOneWidget);
  });

  testWidgets('error no-ApiException: cae al mensaje genérico', (tester) async {
    await _pump(tester, AsyncError<String>(Exception('x'), StackTrace.empty));
    expect(find.text('Ocurrió un error.'), findsOneWidget);
  });

  testWidgets('error sin onRetry: no muestra botón', (tester) async {
    await _pump(
      tester,
      const AsyncError<String>(
        ApiException(status: 500, title: 'Error'),
        StackTrace.empty,
      ),
    );
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('error con onRetry: muestra y dispara el botón', (tester) async {
    var retried = 0;
    await _pump(
      tester,
      const AsyncError<String>(
        ApiException(status: 500, title: 'Error'),
        StackTrace.empty,
      ),
      onRetry: () => retried++,
    );

    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(retried, 1);
  });
}
