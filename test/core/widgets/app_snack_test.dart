import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';

// Helpers de SnackBar compartidos. Interesa el mapeo de errores: ApiException
// usa su .message en español; cualquier otro error cae a "Ocurrió un error.".

Future<void> _pumpButton(
  WidgetTester tester,
  void Function(BuildContext) onPressed,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => onPressed(ctx),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('showSuccessSnack muestra el mensaje tal cual', (tester) async {
    await _pumpButton(tester, (ctx) => showSuccessSnack(ctx, 'Guardado'));
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, 'Guardado'), findsOneWidget);
  });

  testWidgets('showInfoSnack muestra el mensaje informativo', (tester) async {
    await _pumpButton(tester, (ctx) => showInfoSnack(ctx, 'Procesando...'));
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, 'Procesando...'), findsOneWidget);
  });

  testWidgets('showErrorSnack con ApiException usa su .message', (
    tester,
  ) async {
    const error = ApiException(
      status: 0,
      title: 'Sin conexión',
      isConnectionError: true,
    );
    await _pumpButton(tester, (ctx) => showErrorSnack(ctx, error));
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(
      find.widgetWithText(
        SnackBar,
        'No se pudo completar. Intentá de nuevo en un momento.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('showErrorSnack con un error cualquiera cae a genérico', (
    tester,
  ) async {
    await _pumpButton(tester, (ctx) => showErrorSnack(ctx, Exception('boom')));
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, 'Ocurrió un error.'), findsOneWidget);
  });

  testWidgets('showErrorSnack con un String muestra ese mensaje', (
    tester,
  ) async {
    await _pumpButton(tester, (ctx) => showErrorSnack(ctx, 'Falta el dato.'));
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.widgetWithText(SnackBar, 'Falta el dato.'), findsOneWidget);
  });

  testWidgets('un nuevo snack reemplaza al anterior (clearSnackBars)', (
    tester,
  ) async {
    await _pumpButton(tester, (ctx) {
      showSuccessSnack(ctx, 'Primero');
      showSuccessSnack(ctx, 'Segundo');
    });
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(find.text('Primero'), findsNothing);
    expect(find.widgetWithText(SnackBar, 'Segundo'), findsOneWidget);
  });
}
