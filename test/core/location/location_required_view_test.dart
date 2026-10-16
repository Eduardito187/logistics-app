import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/location_required_view.dart';

// Pantalla de bloqueo cuando falta el permiso "siempre". Es puramente
// presentacional: muestra el mensaje y dos botones que disparan los callbacks.

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onRetry,
  required VoidCallback onOpenSettings,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LocationRequiredView(
          onRetry: onRetry,
          onOpenSettings: onOpenSettings,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra el título, el ícono y los dos botones', (tester) async {
    await _pump(tester, onRetry: () {}, onOpenSettings: () {});

    expect(
      find.text('La ubicación es obligatoria para operar el camión'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.location_off), findsOneWidget);
    expect(find.text('Abrir Ajustes'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('"Abrir Ajustes" dispara onOpenSettings', (tester) async {
    var opened = 0;
    await _pump(tester, onRetry: () {}, onOpenSettings: () => opened++);

    await tester.tap(find.text('Abrir Ajustes'));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('"Reintentar" dispara onRetry', (tester) async {
    var retried = 0;
    await _pump(tester, onRetry: () => retried++, onOpenSettings: () {});

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(retried, 1);
  });
}
