import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/navigation/keyboard_dismiss_observer.dart';

// El observer cierra el teclado (quita el foco) en cada cambio de ruta: si un
// campo tenía el foco en la pantalla anterior, no debe quedar enfocado —y el
// teclado abierto— sobre la siguiente.

void main() {
  testWidgets('al empujar otra ruta se pierde el foco del campo anterior', (
    tester,
  ) async {
    final navKey = GlobalKey<NavigatorState>();
    final fieldFocus = FocusNode();
    addTearDown(fieldFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        navigatorObservers: [KeyboardDismissObserver()],
        home: Scaffold(
          body: TextField(
            focusNode: fieldFocus,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Buscar'),
          ),
        ),
      ),
    );
    await tester.pump();

    // El campo arrancó con el foco (autofocus): el teclado estaría abierto.
    expect(fieldFocus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    // Navegar a una pantalla SIN inputs.
    unawaited(
      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Sin campos')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin campos'), findsOneWidget);
    // El campo anterior soltó el foco y el teclado se cerró.
    expect(fieldFocus.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('un diálogo con autofocus SÍ recupera el teclado tras el push', (
    tester,
  ) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        navigatorObservers: [KeyboardDismissObserver()],
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    await tester.pump();

    // Un diálogo con un campo autofocus (como "Asignar vehículo" o el motivo de
    // reimpresión): su autofoco corre DESPUÉS del push del observer, así que el
    // teclado se abre como corresponde.
    final dialogFocus = FocusNode();
    addTearDown(dialogFocus.dispose);
    unawaited(
      showDialog<void>(
        context: navKey.currentContext!,
        builder: (_) => Dialog(
          child: TextField(
            focusNode: dialogFocus,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Placa'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(dialogFocus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
