import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/widgets/empty_state.dart';
import 'package:logistics_app/core/icons/icons.dart';

import '../../support/app_icon_finders.dart';

// Estado vacío reutilizable: ícono + título, con mensaje y acción opcionales.
Future<void> _pump(WidgetTester tester, Widget w) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: w)));
}

void main() {
  testWidgets('muestra ícono y título', (tester) async {
    await _pump(
      tester,
      const EmptyState(icon: AppIcon.inbox, title: 'Sin pendientes'),
    );
    expect(findAppIcon(AppIcon.inbox), findsOneWidget);
    expect(find.text('Sin pendientes'), findsOneWidget);
  });

  testWidgets('muestra el mensaje cuando se provee', (tester) async {
    await _pump(
      tester,
      const EmptyState(
        icon: AppIcon.inbox,
        title: 'Vacío',
        message: 'No hay nada por ahora',
      ),
    );
    expect(find.text('No hay nada por ahora'), findsOneWidget);
  });

  testWidgets('sin mensaje solo muestra el título', (tester) async {
    await _pump(tester, const EmptyState(icon: AppIcon.inbox, title: 'Vacío'));
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('muestra la acción cuando se provee', (tester) async {
    await _pump(
      tester,
      EmptyState(
        icon: AppIcon.cloudOff,
        title: 'Error',
        action: FilledButton(onPressed: () {}, child: const Text('Reintentar')),
      ),
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
