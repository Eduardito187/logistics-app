import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/notification_field.dart';

// NotificationField: fila etiqueta/valor del detalle de una notificación.

void main() {
  testWidgets('muestra etiqueta y valor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationField(label: 'Tipo', value: 'En ruta'),
        ),
      ),
    );

    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('En ruta'), findsOneWidget);
  });
}
