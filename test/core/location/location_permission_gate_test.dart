// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/location_permission_gate.dart';
import 'package:logistics_app/core/location/location_required_view.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Gate de permiso de ubicación. Se sustituye LocationService por un fake vía
// override del provider para controlar si el permiso está concedido, y se
// observan los tres estados (checking/granted/denied) y la re-verificación al
// volver de los ajustes (ciclo de vida resumed).

class _FakeLocationService extends LocationService {
  _FakeLocationService();

  /// Resultado fijo si [completer] es null; si no, se resuelve manualmente.
  bool result = true;
  Completer<bool>? completer;
  int calls = 0;

  @override
  Future<bool> ensureBackgroundPermission() {
    calls++;
    final c = completer;
    if (c != null) return c.future;
    return Future<bool>.value(result);
  }
}

class _FakePermissions extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  int openSettingsCalls = 0;

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    return true;
  }
}

Future<void> _pumpGate(WidgetTester tester, _FakeLocationService fake) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [locationServiceProvider.overrideWithValue(fake)],
      child: const MaterialApp(
        home: Scaffold(body: LocationPermissionGate(child: Text('CONTENIDO'))),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra spinner mientras verifica (checking)', (tester) async {
    final fake = _FakeLocationService()..completer = Completer<bool>();
    await _pumpGate(tester, fake);

    // Aún sin resolver el permiso: spinner y nada de contenido.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('CONTENIDO'), findsNothing);

    fake.completer!.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('CONTENIDO'), findsOneWidget);
  });

  testWidgets('permiso concedido: muestra el child', (tester) async {
    final fake = _FakeLocationService()..result = true;
    await _pumpGate(tester, fake);
    await tester.pumpAndSettle();

    expect(find.text('CONTENIDO'), findsOneWidget);
    expect(find.byType(LocationRequiredView), findsNothing);
  });

  testWidgets('permiso denegado: bloquea con LocationRequiredView', (
    tester,
  ) async {
    final fake = _FakeLocationService()..result = false;
    await _pumpGate(tester, fake);
    await tester.pumpAndSettle();

    expect(find.byType(LocationRequiredView), findsOneWidget);
    expect(find.text('CONTENIDO'), findsNothing);
  });

  testWidgets('al volver de ajustes (resumed) re-verifica y deja pasar', (
    tester,
  ) async {
    final fake = _FakeLocationService()..result = false;
    await _pumpGate(tester, fake);
    await tester.pumpAndSettle();
    expect(find.byType(LocationRequiredView), findsOneWidget);
    final callsBefore = fake.calls;

    // El usuario concede el permiso en Ajustes y vuelve a la app.
    fake.result = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(fake.calls, greaterThan(callsBefore));
    expect(find.text('CONTENIDO'), findsOneWidget);
  });

  testWidgets('resumed NO re-verifica si el permiso ya estaba concedido', (
    tester,
  ) async {
    final fake = _FakeLocationService()..result = true;
    await _pumpGate(tester, fake);
    await tester.pumpAndSettle();
    final callsAfterGrant = fake.calls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // Solo re-verifica cuando el estado es denied; concedido no vuelve a chequear.
    expect(fake.calls, callsAfterGrant);
  });

  testWidgets(
    'concedido se cachea en la sesión: otra pantalla no re-chequea ni muestra spinner',
    (tester) async {
      final fake = _FakeLocationService()..result = true;
      final container = ProviderContainer(
        overrides: [locationServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      Widget gate(String text) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // Key distinta = pantalla nueva (State nuevo, initState de nuevo).
          home: Scaffold(
            body: LocationPermissionGate(
              key: ValueKey(text),
              child: Text(text),
            ),
          ),
        ),
      );

      await tester.pumpWidget(gate('PANTALLA 1'));
      await tester.pumpAndSettle();
      expect(find.text('PANTALLA 1'), findsOneWidget);
      expect(fake.calls, 1);
      expect(container.read(backgroundLocationPermissionProvider), isTrue);

      // Navegar a otra pantalla con el gate: el primer frame ya es el
      // contenido (sin spinner) y no se llama a la plataforma.
      await tester.pumpWidget(gate('PANTALLA 2'));
      expect(find.text('PANTALLA 2'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(fake.calls, 1);
    },
  );

  testWidgets('denegado no se cachea como concedido: se vuelve a verificar', (
    tester,
  ) async {
    final fake = _FakeLocationService()..result = false;
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    Widget gate(Key key) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: LocationPermissionGate(key: key, child: const Text('OK')),
        ),
      ),
    );

    await tester.pumpWidget(gate(const ValueKey(1)));
    await tester.pumpAndSettle();
    expect(container.read(backgroundLocationPermissionProvider), isFalse);

    fake.result = true;
    await tester.pumpWidget(gate(const ValueKey(2)));
    await tester.pumpAndSettle();
    expect(fake.calls, 2);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('"Reintentar" vuelve a verificar el permiso', (tester) async {
    final fake = _FakeLocationService()..result = false;
    await _pumpGate(tester, fake);
    await tester.pumpAndSettle();
    final before = fake.calls;

    fake.result = true;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(fake.calls, greaterThan(before));
    expect(find.text('CONTENIDO'), findsOneWidget);
  });

  testWidgets('"Abrir Ajustes" llama a openAppSettings del plugin', (
    tester,
  ) async {
    final perms = _FakePermissions();
    PermissionHandlerPlatform.instance = perms;

    final fake = _FakeLocationService()..result = false;
    await _pumpGate(tester, fake);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir Ajustes'));
    await tester.pump();

    expect(perms.openSettingsCalls, 1);
  });
}
