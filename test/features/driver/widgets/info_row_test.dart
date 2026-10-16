import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/widgets/info_row.dart';

import '../support/driver_test_support.dart';

// Fila de ícono + texto.

void main() {
  testWidgets('muestra el ícono y el texto', (tester) async {
    await pumpScoped(
      tester,
      child: const Scaffold(
        body: InfoRow(icon: Icons.place, text: 'Av. Central 100'),
      ),
    );

    expect(find.byIcon(Icons.place), findsOneWidget);
    expect(find.text('Av. Central 100'), findsOneWidget);
  });
}
