import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/widgets/assign_lane_dialog.dart';

// Diálogo de asignación de carril/vehículo. Devuelve el texto por Navigator.pop
// (o null si se cancela). El botón "Escanear" abre la cámara (no se prueba acá).

/// Abre el diálogo y deja su resultado en `box` (un [List] de un solo hueco)
/// cuando se cierra. `box[0]` vale `#pending` hasta que el diálogo se resuelve.
Future<void> _open(
  WidgetTester tester,
  List<Object?> box, {
  String? initial,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              box[0] = await showDialog<String>(
                context: context,
                builder: (_) => AssignLaneDialog(initial: initial),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('escribir y "Guardar" devuelve el valor ingresado', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.enterText(find.byType(TextField), 'Carril 3');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.byType(AssignLaneDialog), findsNothing);
    expect(box[0], 'Carril 3');
  });

  testWidgets('"Cancelar" cierra devolviendo null', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AssignLaneDialog), findsNothing);
    expect(box[0], isNull);
  });

  testWidgets('enviar desde el teclado (onSubmitted) devuelve el valor', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.enterText(find.byType(TextField), 'ABC-999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(box[0], 'ABC-999');
  });

  testWidgets('"Guardar" con el campo vacío devuelve cadena vacía', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // FALENCIA DETECTADA: AssignLaneDialog.build (assign_lane_dialog.dart:74)
    // "Guardar" hace pop(_controller.text) sin validar ni recortar: con el
    // campo vacío devuelve '' (no null como "Cancelar"). Hoy la pantalla lo
    // compensa recortando/ignorando vacío, pero el diálogo debería devolver
    // null o bloquear Guardar cuando no hay valor. Se verifica el comportamiento
    // ACTUAL para dejar constancia.
    expect(box[0], '');
  });

  testWidgets('precarga el valor inicial recibido', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box, initial: 'ABC-123');

    expect(find.text('ABC-123'), findsOneWidget);
  });

  testWidgets('tiene título y acciones Guardar, Cancelar y Escanear', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    expect(find.text('Carril / vehículo'), findsOneWidget); // título
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Escanear'), findsOneWidget);
  });
}
