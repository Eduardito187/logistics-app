import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/domain/entities/due_maintenance_urgency.dart';
import 'package:logistics_app/features/driver/presentation/widgets/urgency_pill.dart';

import '../support/driver_test_support.dart';

// Chip de urgencia del mantenimiento.

void main() {
  testWidgets('vencido muestra "Vencido"', (tester) async {
    await pumpScoped(
      tester,
      child: const Scaffold(
        body: UrgencyPill(urgency: DueMaintenanceUrgency.overdue),
      ),
    );
    expect(find.text('Vencido'), findsOneWidget);
  });

  testWidgets('por vencer muestra "Por vencer"', (tester) async {
    await pumpScoped(
      tester,
      child: const Scaffold(
        body: UrgencyPill(urgency: DueMaintenanceUrgency.dueSoon),
      ),
    );
    expect(find.text('Por vencer'), findsOneWidget);
  });

  testWidgets('programado muestra "Programado"', (tester) async {
    await pumpScoped(
      tester,
      child: const Scaffold(
        body: UrgencyPill(urgency: DueMaintenanceUrgency.scheduled),
      ),
    );
    expect(find.text('Programado'), findsOneWidget);
  });
}
