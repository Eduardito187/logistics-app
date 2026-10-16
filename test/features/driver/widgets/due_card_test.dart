import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/domain/entities/due_maintenance_item.dart';
import 'package:logistics_app/features/driver/presentation/widgets/due_card.dart';
import 'package:logistics_app/features/driver/presentation/widgets/urgency_pill.dart';

import '../support/driver_test_support.dart';

// Tarjeta de un mantenimiento por vencer. Se usan números < 1000 para no
// depender del separador de miles del locale.

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  testWidgets('muestra servicio, vehículo, detalles y urgencia', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: DueCard(
          item: const DueMaintenanceItem(
            overdue: false,
            plate: 'ABC-123',
            serviceKind: MaintenancePlanServiceKind.oilChange,
            remainingDays: 5,
            remainingKm: 200,
            currentKm: 300,
            nextDueKm: 900,
          ),
        ),
      ),
    );

    expect(find.text('Cambio de aceite'), findsOneWidget);
    expect(find.text('Vehículo: ABC-123'), findsOneWidget);
    expect(find.text('Faltan 5 días'), findsOneWidget);
    expect(find.text('Faltan 200 km'), findsOneWidget);
    expect(find.text('Actual: 300 km'), findsOneWidget);
    expect(find.text('A los 900 km'), findsOneWidget);
    // Por vencer (remainingKm <= 500 => dueSoon).
    expect(find.byType(UrgencyPill), findsOneWidget);
    expect(find.text('Por vencer'), findsOneWidget);
  });

  testWidgets('vencido muestra días/km en negativo y chip Vencido', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: DueCard(
          item: const DueMaintenanceItem(
            overdue: true,
            serviceKind: MaintenancePlanServiceKind.brakes,
            remainingDays: -3,
            remainingKm: -40,
          ),
        ),
      ),
    );

    expect(find.text('Frenos'), findsOneWidget);
    expect(find.text('Vencido hace 3 días'), findsOneWidget);
    expect(find.text('Pasado por 40 km'), findsOneWidget);
    expect(find.text('Vencido'), findsOneWidget);
  });

  testWidgets('vence hoy cuando remaining_days es 0', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: DueCard(
          item: const DueMaintenanceItem(overdue: false, remainingDays: 0),
        ),
      ),
    );
    expect(find.text('Vence hoy'), findsOneWidget);
  });

  testWidgets('sin plate usa el vehicleId y sin servicio usa "Mantenimiento"', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: DueCard(
          item: const DueMaintenanceItem(overdue: false, vehicleId: 'v-99'),
        ),
      ),
    );
    expect(find.text('Mantenimiento'), findsOneWidget);
    expect(find.text('Vehículo: v-99'), findsOneWidget);
  });
}
