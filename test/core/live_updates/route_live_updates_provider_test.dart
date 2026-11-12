import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/live_updates/live_updates_service.dart';
import 'package:logistics_app/core/live_updates/route_island.dart';
import 'package:logistics_app/core/live_updates/route_live_state.dart';
import 'package:logistics_app/core/live_updates/route_live_status.dart';
import 'package:logistics_app/core/live_updates/route_live_updates_controller.dart';
import 'package:logistics_app/core/live_updates/route_live_updates_provider.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/locally_settled_stops.dart';

import '../../features/driver/support/driver_test_support.dart';

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this._initial);

  final Session? _initial;

  @override
  Session? build() => _initial;

  void set(Session? session) => state = session;
}

class _FakeService extends LiveUpdatesService {
  final List<String> calls = [];
  RouteLiveStatus? last;

  @override
  Future<bool> start(RouteLiveStatus status) async {
    calls.add('start');
    last = status;
    return true;
  }

  @override
  Future<bool> update(RouteLiveStatus status) async {
    calls.add('update');
    last = status;
    return true;
  }

  @override
  Future<bool> end([RouteLiveStatus? last]) async {
    calls.add('end');
    return true;
  }

  final List<String> island = [];

  @override
  Future<bool> showOverlay(RouteLiveStatus status) async {
    island.add('show');
    return true;
  }

  @override
  Future<bool> hideOverlay() async {
    island.add('hide');
    return true;
  }

  @override
  Future<bool> setPromotionEnabled(bool enabled) async {
    island.add('promote:$enabled');
    return true;
  }
}

const _driver = Session(userName: 'chofer', role: UserRole.driver);
const _picker = Session(userName: 'prep', role: UserRole.picker);

DriverRoute _route() => buildRoute(
  totalStops: 2,
  completedStops: 0,
  stops: [
    buildStop(id: 's1', sequence: 1, customerName: 'Ana'),
    buildStop(id: 's2', sequence: 2, customerName: 'Beto'),
  ],
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeService service;
  late ProviderContainer container;
  var routeCalls = 0;

  ProviderContainer build(Session? session) {
    service = _FakeService();
    routeCalls = 0;
    final c = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _TestSessionNotifier(session)),
        driverRouteProvider.overrideWith((ref) async {
          routeCalls++;
          return _route();
        }),
        routeLiveFixProvider.overrideWithValue(null),
        routeLiveUpdatesControllerProvider.overrideWith(
          (ref) => RouteLiveUpdatesController(service: service),
        ),
      ],
    );
    c.listen(routeLiveUpdatesProvider, (_, _) {});
    return c;
  }

  tearDown(() => container.dispose());

  test('chofer con ruta activa → start con la parada en curso', () async {
    container = build(_driver);
    await _settle();
    await _settle();
    expect(service.calls, ['start']);
    expect(service.last!.stopId, 's1');
    expect(service.last!.state, RouteLiveState.onTheWay);
  });

  test('resolver la parada en este teléfono → update a la siguiente', () async {
    container = build(_driver);
    await _settle();
    await _settle();
    container
        .read(locallySettledStopsProvider.notifier)
        .settle('s1', DriverRouteStopStatus.completed);
    await _settle();
    await _settle();
    expect(service.calls, ['start', 'update']);
    expect(service.last!.stopId, 's2');
    expect(service.last!.completedCount, 1);
  });

  test('cerrar sesión → end', () async {
    container = build(_driver);
    await _settle();
    await _settle();
    (container.read(sessionProvider.notifier) as _TestSessionNotifier).set(
      null,
    );
    await _settle();
    await _settle();
    expect(service.calls, ['start', 'end']);
  });

  test('otro rol: no pide la ruta y no muestra nada', () async {
    container = build(_picker);
    await _settle();
    await _settle();
    expect(routeCalls, 0);
    expect(service.calls, ['end'], reason: 'solo limpia huérfanas');
  });

  test(
    'Android: con el servicio arriba re-publica y la isla de DisTrack aparece',
    () async {
      service = _FakeService();
      container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(() => _TestSessionNotifier(_driver)),
          driverRouteProvider.overrideWith((ref) async => _route()),
          routeLiveFixProvider.overrideWithValue(null),
          routeLiveServiceRunningProvider.overrideWithValue(true),
          routeIslandModeProvider.overrideWithValue(RouteIslandMode.overlay),
          routeLiveUpdatesControllerProvider.overrideWith(
            (ref) => RouteLiveUpdatesController(
              service: service,
              hideInForeground: true,
              foreground: false,
            ),
          ),
        ],
      );
      container.listen(routeLiveUpdatesProvider, (_, _) {});
      await _settle();
      await _settle();
      // Servicio arriba antes de la ruta → al llegar la ruta, start normal.
      expect(service.calls, ['start']);
      expect(service.last!.stopId, 's1');
      expect(service.island, ['promote:false', 'show']);
      final controller = container.read(routeLiveUpdatesControllerProvider);
      expect(controller.serviceRunning, isTrue);
      expect(controller.islandMode, RouteIslandMode.overlay);
    },
  );
}
