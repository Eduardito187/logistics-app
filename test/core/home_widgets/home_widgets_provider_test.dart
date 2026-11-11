import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/home_widgets/home_widget_kind.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_prefs_notifier.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_prefs_store.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_provider.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_service.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/locally_settled_stops.dart';
import 'package:logistics_app/features/picking/presentation/controllers/orders_worklist_controller.dart';

import '../../features/driver/support/driver_test_support.dart';
import '../../features/supervisor/support/supervisor_fixtures.dart';
import '../auth/test_fakes.dart';

// Arranque de los widgets con el canal nativo simulado
// (setMockMethodCallHandler): login → setEnabledKinds + payloads del rol;
// logout → SOLO clearAll; datos solo de providers que ya están vivos.

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this._initial);

  final Session? _initial;

  @override
  Session? build() => _initial;

  void set(Session? session) => state = session;
}

const _driver = Session(userName: 'Chofer', role: UserRole.driver);
const _picker = Session(userName: 'prep', role: UserRole.picker);

DriverRoute _route() => buildRoute(
  totalStops: 2,
  completedStops: 0,
  stops: [
    buildStop(id: 's1', sequence: 1, customerName: 'Ana', address: 'Calle 1'),
    buildStop(id: 's2', sequence: 2, customerName: 'Beto'),
  ],
);

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = HomeWidgetsService.defaultChannel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late FakeSecureStorage storage;
  var ordersCalls = 0;

  ProviderContainer build(Session? session) {
    final c = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _TestSessionNotifier(session)),
        secureStorageProvider.overrideWithValue(storage),
        homeWidgetsClockProvider.overrideWithValue(
          () => DateTime(2026, 10, 15, 9),
        ),
        driverRouteProvider.overrideWith((ref) async => _route()),
        ordersToPrepareProvider.overrideWith((ref) async {
          ordersCalls++;
          return [shipment(ShipmentStatus.received, id: 'a')];
        }),
      ],
    );
    addTearDown(c.dispose);
    c.listen(homeWidgetsProvider, (_, _) {});
    return c;
  }

  Iterable<MethodCall> updatesOf(HomeWidgetKind kind) => calls.where(
    (c) =>
        c.method == 'update' &&
        (c.arguments as Map)['kind'] == kind.backendKey,
  );

  Map<Object?, Object?> lastPayload(HomeWidgetKind kind) =>
      (updatesOf(kind).last.arguments as Map)['payload'] as Map;

  setUp(() {
    calls = [];
    storage = FakeSecureStorage();
    ordersCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('sin sesión al arrancar: clearAll y nunca setEnabledKinds', () async {
    build(null);
    await _settle();
    expect(calls.map((c) => c.method), ['clearAll']);
  });

  test('login chofer: setEnabledKinds con la unión y payloads', () async {
    final c = build(_driver);
    await _settle();
    final enabled = calls.where((c) => c.method == 'setEnabledKinds');
    expect(enabled.single.arguments, {
      'kinds': ['next_delivery', 'route_day', 'quick_scan'],
    });
    expect(lastPayload(HomeWidgetKind.pickingPending)['state'], 'notAllowed');
    expect(lastPayload(HomeWidgetKind.quickScan)['route'], '/driver/load');
    // La ruta todavía no la cargó nadie: estado inicial.
    expect(lastPayload(HomeWidgetKind.nextDelivery)['state'], 'empty');

    // La pantalla de entrega carga la ruta → el widget la refleja.
    c.listen(driverRouteProvider, (_, _) {});
    await _settle();
    expect(lastPayload(HomeWidgetKind.nextDelivery)['customer'], 'Ana');
    expect(lastPayload(HomeWidgetKind.routeDay)['pending'], 2);

    // Parada resuelta en este teléfono → avanza al instante.
    c
        .read(locallySettledStopsProvider.notifier)
        .settle('s1', DriverRouteStopStatus.completed);
    await _settle();
    expect(lastPayload(HomeWidgetKind.nextDelivery)['customer'], 'Beto');
    expect(lastPayload(HomeWidgetKind.routeDay)['delivered'], 1);
  });

  test('privacidad: ocultar cliente se aplica al instante', () async {
    final c = build(_driver);
    c.listen(driverRouteProvider, (_, _) {});
    await _settle();
    expect(lastPayload(HomeWidgetKind.nextDelivery)['address'], 'Calle 1');
    await c.read(homeWidgetsPrefsProvider.notifier).setHideCustomer(true);
    await _settle();
    expect(lastPayload(HomeWidgetKind.nextDelivery)['customer'], 'Cliente');
    expect(lastPayload(HomeWidgetKind.nextDelivery)['address'], isNull);
    // Guardado por usuario.
    expect(
      storage.data[HomeWidgetsPrefsStore.storageKeyFor('chofer')],
      contains('"hideCustomer":true'),
    );
  });

  test('preferencias del usuario: kinds apagados no se habilitan', () async {
    storage.seed(
      HomeWidgetsPrefsStore.storageKeyFor('chofer'),
      '{"disabled":["route_day"],"hideCustomer":false}',
    );
    build(_driver);
    await _settle();
    expect(calls.firstWhere((c) => c.method == 'setEnabledKinds').arguments, {
      'kinds': ['next_delivery', 'quick_scan'],
    });
  });

  test('apagar un widget → setEnabledKinds sin ese kind', () async {
    final c = build(_driver);
    await _settle();
    await c
        .read(homeWidgetsPrefsProvider.notifier)
        .setKindEnabled(HomeWidgetKind.routeDay, false);
    await _settle();
    expect(calls.where((c) => c.method == 'setEnabledKinds').last.arguments, {
      'kinds': ['next_delivery', 'quick_scan'],
    });
  });

  test('logout: SOLO clearAll (nunca setEnabledKinds)', () async {
    final c = build(_driver);
    await _settle();
    calls.clear();
    (c.read(sessionProvider.notifier) as _TestSessionNotifier).set(null);
    await _settle();
    expect(calls.map((c) => c.method), ['clearAll']);
  });

  test('no pide datos para los widgets (escucha débil)', () async {
    final c = build(_picker);
    await _settle();
    expect(ordersCalls, 0);
    expect(lastPayload(HomeWidgetKind.pickingPending)['state'], 'empty');
    // La worklist se abre → el widget refleja lo que ya cargó.
    c.listen(ordersToPrepareProvider, (_, _) {});
    await _settle();
    expect(ordersCalls, 1);
    expect(lastPayload(HomeWidgetKind.pickingPending)['pending'], 1);
  });
}
