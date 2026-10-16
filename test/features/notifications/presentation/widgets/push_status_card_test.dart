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

  testWidgets('registered con token: "Activo", oculta botón y confirma', (
    tester,
  ) async {
    await _pump(
      tester,
      const PushStatus(
        state: PushRegistrationState.registered,
        token: 'fcm-token-abc',
      ),
    );

    expect(find.text('Activo'), findsOneWidget);
    expect(_pillTone(tester), PillTone.success);
    // Registrado: ya no se ofrece activar y el token no se muestra.
    expect(find.text('Activar notificaciones'), findsNothing);
    expect(
      find.text('Recibirás avisos de la operación en este teléfono.'),
      findsOneWidget,
    );
    expect(find.textContaining('fcm-token-abc'), findsNothing);
  });

  testWidgets('unavailable (sin credenciales): "No disponible", sin botón', (
    tester,
  ) async {
    await _pump(
      tester,
      const PushStatus(
        state: PushRegistrationState.unavailable,
        message: 'Las notificaciones push todavía no están configuradas.',
      ),
    );

    expect(find.text('No disponible'), findsOneWidget);
    expect(_pillTone(tester), PillTone.warning);
    expect(
      find.text('Las notificaciones push todavía no están configuradas.'),
      findsOneWidget,
    );
    expect(find.text('Activar notificaciones'), findsNothing);
  });

  testWidgets('failed: "Error", mensaje y botón para reintentar', (
    tester,
  ) async {
    await _pump(
      tester,
      const PushStatus(
        state: PushRegistrationState.failed,
        message: 'Permiso de notificaciones denegado.',
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(_pillTone(tester), PillTone.danger);
    expect(find.text('Permiso de notificaciones denegado.'), findsOneWidget);
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
