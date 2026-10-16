import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/driver/domain/entities/due_maintenance_item.dart';
import 'package:logistics_app/features/driver/presentation/controllers/fleet_ops_controllers.dart';
import 'package:logistics_app/features/driver/presentation/maintenance_due_screen.dart';
import 'package:logistics_app/features/driver/presentation/widgets/due_card.dart';

import '../support/driver_test_support.dart';

// Mantenimiento por vencer (solo lectura). No usa el gate del chofer.

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  testWidgets('sin items muestra "Todo al día"', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        dueMaintenanceProvider.overrideWith(
          (ref) async => <DueMaintenanceItem>[],
        ),
      ],
      child: const MaintenanceDueScreen(),
    );

    expect(find.text('Todo al día'), findsOneWidget);
    expect(find.text('No hay mantenimientos por vencer.'), findsOneWidget);
  });

  testWidgets('lista los mantenimientos por vencer', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        dueMaintenanceProvider.overrideWith(
          (ref) async => const [
            DueMaintenanceItem(
              overdue: true,
              serviceKind: MaintenancePlanServiceKind.brakes,
              remainingDays: -2,
            ),
            DueMaintenanceItem(
              overdue: false,
              serviceKind: MaintenancePlanServiceKind.tires,
              remainingKm: 400,
            ),
          ],
        ),
      ],
      child: const MaintenanceDueScreen(),
    );

    expect(find.byType(DueCard), findsNWidgets(2));
    expect(find.text('Frenos'), findsOneWidget);
    expect(find.text('Llantas'), findsOneWidget);
    expect(find.text('Vencido'), findsOneWidget);
    expect(find.text('Por vencer'), findsOneWidget);
  });

  testWidgets('en error muestra el estado de carga con reintento', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        dueMaintenanceProvider.overrideWith(
          (ref) async => throw const ApiException(status: 500, title: 'x'),
        ),
      ],
      child: const MaintenanceDueScreen(),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
