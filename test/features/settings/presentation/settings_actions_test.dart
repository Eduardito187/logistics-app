import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/settings/presentation/settings_actions.dart';

// Utilidades de escritura con red del feature de ajustes: runSettingsAction
// (carga + éxito/error) y confirmSettingsAction (diálogo de confirmación).

void main() {
  group('runSettingsAction', () {
    testWidgets('éxito: devuelve true, llama onSuccess y avisa', (
      tester,
    ) async {
      bool? result;
      var onSuccessCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await runSettingsAction(
                    context,
                    action: () async {},
                    success: 'Listo.',
                    onSuccess: () => onSuccessCalled = true,
                  );
                },
                child: const Text('run'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('run'));
      // No se usa pumpAndSettle: el diálogo de carga tiene un spinner infinito.
      await tester.pump(); // muestra diálogo + ejecuta acción
      await tester.pump(); // cierra diálogo + agenda snack
      await tester.pump(const Duration(milliseconds: 50)); // snack visible

      expect(result, isTrue);
      expect(onSuccessCalled, isTrue);
      expect(find.text('Listo.'), findsOneWidget);
    });

    testWidgets('ApiException: devuelve false y muestra el mensaje', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await runSettingsAction(
                    context,
                    action: () async => throw const ApiException(
                      status: 422,
                      title: 'Datos inválidos',
                      detail: 'El dato no sirve.',
                    ),
                    success: 'Listo.',
                  );
                },
                child: const Text('run'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('run'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, isFalse);
      // showErrorSnack usa ApiException.message (detail para un 422 con detail).
      expect(find.text('El dato no sirve.'), findsOneWidget);
      expect(find.text('Listo.'), findsNothing);
    });
  });

  group('confirmSettingsAction', () {
    Future<bool?> showAndTap(WidgetTester tester, String tapLabel) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  confirmed = await confirmSettingsAction(
                    context,
                    title: 'Revocar dispositivo',
                    message: '¿Continuar?',
                    confirmLabel: 'Revocar',
                    destructive: true,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Revocar dispositivo'), findsOneWidget);
      await tester.tap(find.text(tapLabel));
      await tester.pumpAndSettle();
      return confirmed;
    }

    testWidgets('confirmar devuelve true', (tester) async {
      expect(await showAndTap(tester, 'Revocar'), isTrue);
    });

    testWidgets('cancelar devuelve false', (tester) async {
      expect(await showAndTap(tester, 'Cancelar'), isFalse);
    });
  });
}
