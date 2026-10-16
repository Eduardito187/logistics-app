import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plans_date_bar.dart';

// PlansDateBar: muestra el día seleccionado y abre un selector de fecha.

void main() {
  testWidgets('muestra el día formateado y el botón de cambio', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: PlansDateBar(date: DateTime(2026, 3, 9))),
        ),
      ),
    );

    expect(find.text('Planes de 09/03/2026'), findsOneWidget);
    expect(find.text('Cambiar fecha'), findsOneWidget);
  });

  testWidgets('tocar "Cambiar fecha" abre el selector de fecha', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: PlansDateBar(date: DateTime(2026, 3, 9))),
        ),
      ),
    );

    await tester.tap(find.text('Cambiar fecha'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
