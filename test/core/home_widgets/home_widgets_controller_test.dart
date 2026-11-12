import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/home_widgets/home_widget_kind.dart';
import 'package:logistics_app/core/home_widgets/home_widget_state.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_controller.dart';
import 'package:logistics_app/core/home_widgets/picking_pending_payload.dart';
import 'package:logistics_app/core/home_widgets/route_day_payload.dart';

import 'fake_home_widgets_service.dart';

// Controller de los widgets: login/logout, throttling (1 por kind cada 60 s
// salvo cambio de parada/estado), dedupe de payload idéntico y flush al pasar
// a segundo plano. Reloj falso, sin timers.

PickingPendingPayload _picking(int pending) => PickingPendingPayload(
  state: HomeWidgetState.ok,
  route: '/picking/orders',
  pending: pending,
  inProgress: 0,
  scanRoute: '/picking/prepare',
);

RouteDayPayload _day(int delivered) => RouteDayPayload(
  state: HomeWidgetState.ok,
  route: '/driver/route',
  delivered: delivered,
  pending: 5 - delivered,
  failed: 0,
  total: 5,
);

void main() {
  late FakeHomeWidgetsService service;
  late DateTime now;
  late HomeWidgetsController controller;

  setUp(() {
    service = FakeHomeWidgetsService();
    now = DateTime(2026, 11, 11, 9);
    controller = HomeWidgetsController(service: service, clock: () => now);
  });

  group('sesión', () {
    test('login: notAllowed fuera del rol, enabled = rol ∪ quick_scan', () {
      controller.signIn(userKey: 'prep', role: UserRole.picker);
      expect(service.enabledCalls, [
        [HomeWidgetKind.pickingPending, HomeWidgetKind.quickScan],
      ]);
      for (final kind in [
        HomeWidgetKind.nextDelivery,
        HomeWidgetKind.routeDay,
        HomeWidgetKind.storeReceptions,
        HomeWidgetKind.supervisorSummary,
      ]) {
        expect(service.payloads[kind]!['state'], 'notAllowed');
        expect(service.payloads[kind]!['route'], '/home');
      }
      expect(
        service.payloads[HomeWidgetKind.pickingPending]!['state'],
        'empty',
      );
      expect(service.payloads[HomeWidgetKind.quickScan], {
        'state': 'ok',
        'updatedAt': now.millisecondsSinceEpoch,
        'route': '/picking/prepare',
        'label': 'Escanear',
      });
    });

    test('supervisor: quick_scan habilitado pero notAllowed', () {
      controller.signIn(userKey: 'sup', role: UserRole.supervisor);
      expect(service.enabledCalls.single, [
        HomeWidgetKind.supervisorSummary,
        HomeWidgetKind.quickScan,
      ]);
      expect(
        service.payloads[HomeWidgetKind.quickScan]!['state'],
        'notAllowed',
      );
    });

    test('kinds apagados por el usuario no se habilitan (salvo Escanear)', () {
      controller.signIn(
        userKey: 'chofer',
        role: UserRole.driver,
        disabled: {HomeWidgetKind.routeDay, HomeWidgetKind.quickScan},
      );
      expect(service.enabledCalls.single, [
        HomeWidgetKind.nextDelivery,
        HomeWidgetKind.quickScan,
      ]);
      controller.onPayload(_day(1));
      expect(service.updatesOf(HomeWidgetKind.routeDay), 0);
    });

    test('logout: SOLO clearAll, nunca setEnabledKinds; una vez', () {
      controller.signIn(userKey: 'prep', role: UserRole.picker);
      service.calls.clear();
      service.enabledCalls.clear();
      controller.signOut();
      controller.signOut();
      expect(service.calls, ['clearAll']);
      expect(service.enabledCalls, isEmpty);
      // Sin sesión las fotos no se publican.
      controller.onPayload(_picking(3));
      expect(service.calls, ['clearAll']);
    });

    test('re-login idempotente: no repite setEnabledKinds', () {
      controller.signIn(userKey: 'prep', role: UserRole.picker);
      final before = service.calls.length;
      controller.signIn(userKey: 'prep', role: UserRole.picker);
      expect(service.calls.length, before);
    });

    test('apagar y prender: setEnabledKinds y re-envía lo último', () {
      controller.signIn(userKey: 'prep', role: UserRole.picker);
      controller.onPayload(_picking(3));
      controller.signIn(
        userKey: 'prep',
        role: UserRole.picker,
        disabled: {HomeWidgetKind.pickingPending},
      );
      expect(service.enabledCalls.last, [HomeWidgetKind.quickScan]);
      final updates = service.updatesOf(HomeWidgetKind.pickingPending);
      controller.signIn(userKey: 'prep', role: UserRole.picker);
      expect(service.enabledCalls.last, [
        HomeWidgetKind.pickingPending,
        HomeWidgetKind.quickScan,
      ]);
      expect(service.updatesOf(HomeWidgetKind.pickingPending), updates + 1);
      expect(service.payloads[HomeWidgetKind.pickingPending]!['pending'], 3);
    });
  });

  group('throttling y dedupe', () {
    setUp(() => controller.signIn(userKey: 'prep', role: UserRole.picker));

    test('payload idéntico no se reenvía', () {
      controller.onPayload(_picking(3)); // del "empty" a datos: al instante
      expect(service.updatesOf(HomeWidgetKind.pickingPending), 2);
      now = now.add(const Duration(minutes: 5));
      controller.onPayload(_picking(3));
      expect(service.updatesOf(HomeWidgetKind.pickingPending), 2);
    });

    test('cambio menor: máximo 1 cada 60 s; flush publica lo retenido', () {
      controller.onPayload(_picking(3));
      now = now.add(const Duration(seconds: 10));
      controller.onPayload(_picking(4));
      expect(service.payloads[HomeWidgetKind.pickingPending]!['pending'], 3);
      now = now.add(const Duration(seconds: 50));
      controller.onPayload(_picking(5));
      expect(service.payloads[HomeWidgetKind.pickingPending]!['pending'], 5);
      now = now.add(const Duration(seconds: 1));
      controller.onPayload(_picking(6));
      expect(service.payloads[HomeWidgetKind.pickingPending]!['pending'], 5);
      controller.flush();
      expect(service.payloads[HomeWidgetKind.pickingPending]!['pending'], 6);
      expect(
        service.payloads[HomeWidgetKind.pickingPending]!['updatedAt'],
        now.millisecondsSinceEpoch,
      );
    });

    test('cambio de parada (route_day) sale al instante', () {
      // El login del preparador (setUp) ya publicó route_day = notAllowed:
      // se cuenta solo lo de la sesión del chofer.
      final before = service.updatesOf(HomeWidgetKind.routeDay);
      controller.signOut();
      controller.signIn(userKey: 'chofer', role: UserRole.driver);
      controller.onPayload(_day(1));
      now = now.add(const Duration(seconds: 1));
      controller.onPayload(_day(2));
      expect(service.payloads[HomeWidgetKind.routeDay]!['delivered'], 2);
      // "empty" inicial del login + parada 1 + parada 2 (a 1 s, sin throttle).
      expect(service.updatesOf(HomeWidgetKind.routeDay) - before, 3);
    });

    test('kind de otro rol se ignora', () {
      final before = service.calls.length;
      controller.onPayload(_day(1));
      expect(service.calls.length, before);
    });
  });
}
