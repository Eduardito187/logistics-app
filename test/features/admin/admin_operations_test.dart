import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/admin/domain/entities/admin_vehicle.dart';
import 'package:logistics_app/features/admin/presentation/admin_broadcasts_screen.dart';
import 'package:logistics_app/features/admin/presentation/admin_calendar_screen.dart';
import 'package:logistics_app/features/admin/presentation/admin_reschedule_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_fleet_screen.dart';

import '../../support/button_finders.dart';
import 'fake_admin.dart';

// Reprogramar (con vista previa obligatoria), calendario de fechas bloqueadas,
// avisos al personal y el filtro por ciudad de la flota.

Future<void> _pickTomorrow(WidgetTester tester) async {
  await tester.tap(find.text('Elegir nueva fecha'));
  await tester.pumpAndSettle();
  // El selector abre en hoy: se acepta tal cual.
  await tester.tap(find.text('OK').last);
  await tester.pumpAndSettle();
}

void main() {
  group('reprogramar', () {
    const preview = RescheduleShipmentsResult(
      count: 2,
      skippedCount: 1,
      shipments: [
        Shipments2(externalId: 'SO-1', customerName: 'Ana'),
        Shipments2(externalId: 'SO-2', customerName: 'Luis'),
      ],
    );
    const truck = AdminVehicle(
      id: 'v1',
      plate: '904U10',
      status: AdminVehicleStatus.inService,
    );

    testWidgets('sin fecha no consulta y avisa', (tester) async {
      final fake = FakeAdmin(preview: preview);
      await pumpAdmin(tester, fake, const AdminRescheduleScreen());

      await tester.tap(find.text('Ver qué se reprograma'));
      await tester.pump();

      expect(fake.previews, isEmpty);
      expect(find.text('Elegí la nueva fecha de entrega.'), findsOneWidget);
    });

    testWidgets('por camión: primero vista previa, después confirma', (
      tester,
    ) async {
      final fake = FakeAdmin(preview: preview, vehicles: const [truck]);
      await pumpAdmin(tester, fake, const AdminRescheduleScreen());

      await tester.tap(find.text('Elegir camión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('904U10'));
      await tester.pumpAndSettle();
      await _pickTomorrow(tester);
      await tester.tap(find.text('Ver qué se reprograma'));
      await tester.pumpAndSettle();

      // Vista previa: cuántos, cuáles y cuántos se saltean. Nada aplicado.
      expect(fake.previews.single.scope.vehicleId, 'v1');
      expect(fake.applied, isEmpty);
      expect(find.text('Vas a reprogramar 2 pedidos.'), findsOneWidget);
      expect(find.text('1 se saltea porque ya está cerrado.'), findsOneWidget);
      expect(find.text('Pedido SO-1 · Ana'), findsOneWidget);

      await tester.tap(
        findButtonWithText<FilledButton>('Reprogramar 2 pedidos'),
      );
      await tester.pumpAndSettle();

      expect(fake.applied.single.scope.vehicleId, 'v1');
      expect(fake.applied.single.windowStart, '08:00');
      expect(fake.applied.single.windowEnd, '18:00');
      expect(fake.applied.single.notifyCustomer, isTrue);
      expect(find.text('2 pedidos reprogramados'), findsOneWidget);
    });

    testWidgets('un pedido puntual no pide alcance', (tester) async {
      final fake = FakeAdmin(preview: preview);
      await pumpAdmin(
        tester,
        fake,
        const AdminRescheduleScreen(
          target: (shipmentId: 'ship-9', orderNumber: 'SO-900001'),
        ),
      );

      expect(find.text('Pedido SO-900001'), findsOneWidget);
      expect(find.text('Elegir camión'), findsNothing);

      await _pickTomorrow(tester);
      await tester.tap(find.text('Ver qué se reprograma'));
      await tester.pumpAndSettle();

      expect(fake.previews.single.scope.shipmentIds, ['ship-9']);
    });

    testWidgets('sin pedidos no deja confirmar', (tester) async {
      final fake = FakeAdmin(
        preview: const RescheduleShipmentsResult(count: 0),
      );
      await pumpAdmin(
        tester,
        fake,
        const AdminRescheduleScreen(
          target: (shipmentId: 'ship-9', orderNumber: 'SO-9'),
        ),
      );
      await _pickTomorrow(tester);
      await tester.tap(find.text('Ver qué se reprograma'));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay pedidos para reprogramar con esos datos.'),
        findsOneWidget,
      );
      final confirm = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Reprogramar 0 pedidos'),
      );
      expect(confirm.onPressed, isNull);
    });
  });

  group('calendario', () {
    final day = DateTime(2026, 12, 24);

    test(
      'consolida por fecha: bloqueado o con cupo si alguna fila lo dice',
      () {
        final days = consolidateCalendar([
          Days(
            date: day,
            blocked: false,
            available: false,
            municipalityId: 'a',
          ),
          Days(
            date: day,
            blocked: true,
            reason: 'Feriado',
            municipalityId: 'b',
          ),
          Days(date: DateTime(2026, 12, 23), available: true),
        ]);

        expect(days.map((d) => d.date.day), [23, 24]);
        expect(days.last.blocked, isTrue);
        expect(days.last.reason, 'Feriado');
        expect(days.first.available, isTrue);
      },
    );

    testWidgets('bloquear un día pide el motivo', (tester) async {
      final fake = FakeAdmin(calendar: [Days(date: day, available: true)]);
      await pumpAdmin(tester, fake, const AdminCalendarScreen());

      expect(find.text('Con cupo'), findsOneWidget);
      await tester.tap(find.text('Jueves 24/12/2026'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Feriado');
      await tester.tap(find.widgetWithText(FilledButton, 'Bloquear'));
      await tester.pumpAndSettle();

      expect(fake.blocked.single, (date: day, reason: 'Feriado'));
      expect(find.text('Día bloqueado.'), findsOneWidget);
    });

    testWidgets('un día bloqueado se puede desbloquear', (tester) async {
      final fake = FakeAdmin(
        calendar: [Days(date: day, blocked: true, reason: 'Feriado')],
      );
      await pumpAdmin(tester, fake, const AdminCalendarScreen());

      expect(find.text('Bloqueado'), findsOneWidget);
      await tester.tap(find.text('Jueves 24/12/2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear'));
      await tester.pumpAndSettle();

      expect(fake.unblocked.single, day);
    });

    testWidgets('abrir fechas: elige el rango y lo manda', (tester) async {
      final fake = FakeAdmin();
      await pumpAdmin(tester, fake, const AdminCalendarScreen());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await tester.tap(find.text('Abrir fechas'));
      await tester.pumpAndSettle();
      // El selector abre en el mes de hoy: se toca hoy dos veces (rango de
      // un solo día) y se confirma.
      await tester.tap(find.text('${today.day}').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('${today.day}').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(fake.opened.single, (from: today, to: today));
      expect(
        find.text('Fechas abiertas. Los cupos se generan en unos segundos.'),
        findsOneWidget,
      );
    });
  });

  group('avisos', () {
    testWidgets('a todos los de un rol', (tester) async {
      final fake = FakeAdmin();
      await pumpAdmin(tester, fake, const AdminBroadcastsScreen());

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tienda'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Título'),
        'Inventario',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mensaje'),
        'Mañana cerramos a las 16:00.',
      );
      await tester.tap(findButtonWithText<FilledButton>('Enviar aviso'));
      await tester.pumpAndSettle();

      expect(fake.sent.single.role, StaffRoleName.tienda);
      expect(fake.sent.single.userIds, isNull);
      expect(fake.sent.single.title, 'Inventario');
      expect(find.text('Aviso enviado a 12 personas.'), findsOneWidget);
    });

    testWidgets('a una persona (desde su ficha)', (tester) async {
      final fake = FakeAdmin();
      await pumpAdmin(
        tester,
        fake,
        const AdminBroadcastsScreen(person: (userId: 7, name: 'Iker Corona')),
      );

      expect(find.text('Iker Corona'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Hola');
      await tester.enterText(
        find.widgetWithText(TextField, 'Mensaje'),
        'Pasá.',
      );
      await tester.tap(findButtonWithText<FilledButton>('Enviar aviso'));
      await tester.pumpAndSettle();

      expect(fake.sent.single.userIds, [7]);
      expect(fake.sent.single.role, isNull);
    });

    testWidgets('sin título o mensaje no envía', (tester) async {
      final fake = FakeAdmin();
      await pumpAdmin(tester, fake, const AdminBroadcastsScreen());

      await tester.tap(findButtonWithText<FilledButton>('Enviar aviso'));
      await tester.pump();

      expect(fake.sent, isEmpty);
      expect(find.text('Escribí el título y el mensaje.'), findsOneWidget);
    });
  });

  test('flota: ciudades presentes, ordenadas y sin vacíos', () {
    VehicleLive live(String id, String? city) => VehicleLive(
      vehicleId: id,
      lat: -17,
      lng: -63,
      moving: false,
      recordedAt: DateTime(2026, 11, 14),
      city: city,
    );

    expect(
      fleetCities([
        live('a', 'Santa Cruz'),
        live('b', 'La Paz'),
        live('c', 'Santa Cruz'),
        live('d', null),
        live('e', ' '),
      ]),
      ['La Paz', 'Santa Cruz'],
    );
    // Backend anterior (sin ciudad): no hay filtro.
    expect(fleetCities([live('a', null)]), isEmpty);
  });
}
