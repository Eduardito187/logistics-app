import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/auth/presentation/widgets/auth_header.dart';

// Encabezado de marca del login: logo, título y bajada. Widget puro.

void main() {
  testWidgets('muestra logo, título de marca y bajada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AuthHeader())),
    );

    expect(find.text('Dismac Logística'), findsOneWidget);
    expect(
      find.text('La operación de reparto y tienda, en una sola app.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
  });
}
