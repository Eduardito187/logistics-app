import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/core/push/push_status.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';
import 'package:logistics_app/features/notifications/presentation/widgets/push_status_card.dart';

import '../../support/fake_push_controller.dart';

// PushStatusCard: indicador del estado de push con botón de activar. Se prueba
// cada estado del registro (idle/registering/registered/unavailable/failed) y la
// acción de activar.

Future<FakePushController> _pump(WidgetTester tester, PushStatus status) async {
  final fake = FakePushController(status);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pushRegistrationProvider.overrideWith(() => fake)],
      child: const MaterialApp(home: Scaffold(body: PushStatusCard())),
    ),
  );
  await tester.pump();
  return fake;
}

PillTone _pillTone(WidgetTester tester) =>
    tester.widget<StatusPill>(find.byType(StatusPill)).tone;

void main() {
  testWidgets('idle: pastilla "Inactivo" y botón de activar visible', (
    tester,
  ) async {
    await _pump(tester, const PushStatus.idle());

    expect(find.text('Inactivo'), findsOneWidget);
    expect(_pillTone(tester), PillTone.neutral);
    expect(find.text('Activar notificaciones'), findsOneWidget);
  });

  testWidgets('registering: pastilla "Registrando" y botón ocupado', (
    tester,
  ) async {
    await _pump(
      tester,
      const PushStatus(state: PushRegistrationState.registering),
    );

    expect(find.text('Registrando'), findsOneWidget);
    expect(_pillTone(tester), PillTone.info);
    // Estado ocupado: el botón muestra "Activando..." y un spinner.
    expect(find.text('Activando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'registered con endpoint: "Activo", oculta botón y muestra datos',
    (tester) async {
      await _pump(
        tester,
        const PushStatus(
          state: PushRegistrationState.registered,
          endpoint: 'https://ntfy.sh/abc123',
          distributor: 'io.heckel.ntfy',
        ),
      );

      expect(find.text('Activo'), findsOneWidget);
      expect(_pillTone(tester), PillTone.success);
      // Registrado: ya no se ofrece activar.
      expect(find.text('Activar notificaciones'), findsNothing);
      expect(find.text('Distribuidor: io.heckel.ntfy'), findsOneWidget);
      expect(find.text('Endpoint: https://ntfy.sh/abc123'), findsOneWidget);
    },
  );

  testWidgets('unavailable: "Sin distribuidor", mensaje y botón visible', (
    tester,
  ) async {
    await _pump(
      tester,
      const PushStatus(
        state: PushRegistrationState.unavailable,
        message: 'No hay una app de notificaciones instalada.',
      ),
    );

    expect(find.text('Sin distribuidor'), findsOneWidget);
    expect(_pillTone(tester), PillTone.warning);
    expect(
      find.text('No hay una app de notificaciones instalada.'),
      findsOneWidget,
    );
    expect(find.text('Activar notificaciones'), findsOneWidget);
  });

  testWidgets('failed: "Error", mensaje y botón para reintentar', (
    tester,
  ) async {
    await _pump(
      tester,
      const PushStatus(
        state: PushRegistrationState.failed,
        message: 'El distribuidor rechazó el registro.',
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(_pillTone(tester), PillTone.danger);
    expect(find.text('El distribuidor rechazó el registro.'), findsOneWidget);
    expect(find.text('Activar notificaciones'), findsOneWidget);
  });

  testWidgets('tocar "Activar notificaciones" llama a register()', (
    tester,
  ) async {
    final fake = await _pump(tester, const PushStatus.idle());

    await tester.tap(find.text('Activar notificaciones'));
    await tester.pump();

    expect(fake.registerCalls, 1);
  });
}
