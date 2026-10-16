import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/home/presentation/widgets/profile_header.dart';

// Cabecera de perfil del inicio: avatar del rol, nombre y etiqueta. Widget puro.

void main() {
  testWidgets('muestra el nombre, el rol y el ícono', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileHeader(
            name: 'María López',
            role: 'Chofer',
            icon: Icons.local_shipping,
          ),
        ),
      ),
    );

    expect(find.text('María López'), findsOneWidget);
    expect(find.text('Chofer'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
  });
}
