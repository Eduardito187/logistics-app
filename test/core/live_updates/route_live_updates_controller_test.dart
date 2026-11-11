import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/live_updates/live_updates_promotion.dart';
import 'package:logistics_app/core/live_updates/live_updates_service.dart';
import 'package:logistics_app/core/live_updates/route_island.dart';
import 'package:logistics_app/core/live_updates/route_live_state.dart';
import 'package:logistics_app/core/live_updates/route_live_status.dart';
import 'package:logistics_app/core/live_updates/route_live_updates_controller.dart';

/// Servicio falso: registra cada llamada al nativo.
class _FakeService extends LiveUpdatesService {
  final List<String> calls = [];
  final List<RouteLiveStatus?> payloads = [];

  @override
  Future<bool> start(RouteLiveStatus status) async {
    calls.add('start');
    payloads.add(status);
    return true;
  }

  @override
  Future<bool> update(RouteLiveStatus status) async {
    calls.add('update');
    payloads.add(status);
    return true;
  }

  @override
  Future<bool> end([RouteLiveStatus? last]) async {
    calls.add('end');
    payloads.add(last);
    return true;
  }

  /// Isla de DisTrack y promoción (aparte de la notificación, para no romper
  /// las aserciones de [calls]).
  final List<String> island = [];
  RouteLiveStatus? lastOverlay;

  @override
  Future<bool> showOverlay(RouteLiveStatus status) async {
    island.add('show');
    lastOverlay = status;
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

RouteLiveStatus _status({
  String stopId = 's2',
  int stopIndex = 2,
  int completed = 1,
  RouteLiveState state = RouteLiveState.onTheWay,
  double? meters = 2300,
}) => RouteLiveStatus(
  routeId: 'r1',
  stopId: stopId,
  stopIndex: stopIndex,
  stopCount: 5,
  completedCount: completed,
  customer: 'Ana',
  state: state,
  etaAt: DateTime(2026, 11, 11, 10, 30),
  remainingMeters: meters,
);

void main() {
  late _FakeService service;
  late DateTime now;
  late int arrivals;

  setUp(() {
    service = _FakeService();
    now = DateTime(2026, 11, 11, 9);
    arrivals = 0;
  });

  RouteLiveUpdatesController build({
    bool hideInForeground = false,
    bool foreground = true,
  }) => RouteLiveUpdatesController(
    service: service,
    hideInForeground: hideInForeground,
    foreground: foreground,
    clock: () => now,
    onArrived: () => arrivals++,
  );

  test('arranca (start) apenas hay una parada activa', () {
    final c = build();
    c.onStatus(_status());
    expect(service.calls, ['start']);
    expect(c.isShown, isTrue);
  });

  test('la misma foto (o metros que no cambian el texto) no publica', () {
    final c = build();
    c.onStatus(_status());
    c.onStatus(_status());
    c.onStatus(_status(meters: 2320));
    now = now.add(const Duration(minutes: 5));
    c.onStatus(_status(meters: 2340));
    expect(service.calls, ['start']);
  });

  test('solo distancia: máximo un update cada 30 s', () {
    final c = build();
    c.onStatus(_status(meters: 2300));
    now = now.add(const Duration(seconds: 10));
    c.onStatus(_status(meters: 2000));
    expect(service.calls, ['start'], reason: 'antes de 30 s no se publica');
    now = now.add(const Duration(seconds: 25));
    c.onStatus(_status(meters: 1700));
    expect(service.calls, ['start', 'update']);
    expect(service.payloads.last!.remainingText, '1,7 km');
    now = now.add(const Duration(seconds: 5));
    c.onStatus(_status(meters: 1500));
    expect(service.calls, ['start', 'update']);
  });

  test('cambio de parada o de avance se publica al instante', () {
    final c = build();
    c.onStatus(_status());
    now = now.add(const Duration(seconds: 1));
    c.onStatus(_status(stopId: 's3', stopIndex: 3, completed: 2));
    expect(service.calls, ['start', 'update']);
    expect(service.payloads.last!.stopIndex, 3);
  });

  test('llegada: aviso una sola vez por parada, y "Entregando" tras 90 s', () {
    final c = build();
    c.onStatus(_status());
    now = now.add(const Duration(seconds: 1));
    c.onStatus(_status(state: RouteLiveState.arriving, meters: 40));
    expect(arrivals, 1);
    expect(service.calls.last, 'update');
    expect(service.payloads.last!.state, RouteLiveState.arriving);

    now = now.add(const Duration(seconds: 60));
    c.onStatus(_status(state: RouteLiveState.arriving, meters: 30));
    expect(service.payloads.last!.state, RouteLiveState.arriving);

    now = now.add(const Duration(seconds: 31));
    c.onStatus(_status(state: RouteLiveState.arriving, meters: 30));
    expect(service.payloads.last!.state, RouteLiveState.delivering);
    expect(service.payloads.last!.title, 'Entregando · Parada 2 de 5');
    expect(arrivals, 1);
  });

  test('histéresis: el ruido del GPS en el borde no vuelve a "En camino"', () {
    final c = build();
    c.onStatus(_status(state: RouteLiveState.arriving, meters: 50));
    final published = service.calls.length;
    now = now.add(const Duration(seconds: 2));
    // El builder dice "en camino" (75 m) pero sigue cerca: se mantiene.
    c.onStatus(_status(meters: 75));
    expect(service.calls.length, published);
    expect(c.lastSent!.state, RouteLiveState.arriving);
    // Se fue de verdad (> 120 m): vuelve a "en camino".
    now = now.add(const Duration(seconds: 2));
    c.onStatus(_status(meters: 400));
    expect(c.lastSent!.state, RouteLiveState.onTheWay);
  });

  test('ruta finalizada → end con el estado final', () {
    final c = build();
    c.onStatus(_status());
    c.onStatus(_status(stopId: '', state: RouteLiveState.finished));
    expect(service.calls, ['start', 'end']);
    expect(service.payloads.last!.state, RouteLiveState.finished);
    expect(c.isShown, isFalse);
    // No se reabre con la misma ruta terminada.
    c.onStatus(_status(stopId: '', state: RouteLiveState.finished));
    expect(service.calls, ['start', 'end']);
  });

  test('sin ruta / logout → end; la primera vez limpia huérfanas', () {
    final c = build();
    c.onStatus(null);
    expect(service.calls, ['end'], reason: 'limpia una notificación vieja');
    c.onStatus(null);
    expect(service.calls, ['end']);
    c.onStatus(_status());
    c.onStatus(null);
    expect(service.calls, ['end', 'start', 'end']);
  });

  test('Android: oculta con la app en pantalla, muestra en segundo plano', () {
    final c = build(hideInForeground: true);
    c.onStatus(_status());
    expect(service.calls, isEmpty);

    c.setForeground(false);
    expect(service.calls, ['start']);

    now = now.add(const Duration(seconds: 1));
    c.onStatus(_status(stopId: 's3', stopIndex: 3, completed: 2));
    expect(service.calls, ['start', 'update']);

    c.setForeground(true);
    expect(service.calls, ['start', 'update', 'end']);
    // En primer plano las fotos nuevas no se publican.
    c.onStatus(_status(stopId: 's4', stopIndex: 4, completed: 3));
    expect(service.calls.length, 3);

    c.setForeground(false);
    expect(service.calls.last, 'start');
    expect(service.payloads.last!.stopIndex, 4);
  });

  test('iOS: el ciclo de vida no toca la Live Activity', () {
    final c = build();
    c.onStatus(_status());
    c.setForeground(false);
    c.setForeground(true);
    expect(service.calls, ['start']);
  });

  test('dispose quita lo mostrado y deja de publicar', () {
    final c = build();
    c.onStatus(_status());
    c.dispose();
    c.onStatus(_status(stopId: 's3', stopIndex: 3));
    expect(service.calls, ['start', 'end']);
  });

  group('foreground service (una sola notificación, id 4120)', () {
    test('al subir el servicio se re-publica la ruta encima del neutro', () {
      final c = build(hideInForeground: true, foreground: false);
      c.onStatus(_status());
      expect(service.calls, ['start']);
      // Sin cambios de contenido, igual se vuelve a publicar (una vez).
      c.setServiceRunning(true);
      expect(service.calls, ['start', 'update']);
      expect(service.payloads.last!.stopId, 's2');
      // Repetir el mismo estado no publica de nuevo.
      c.setServiceRunning(true);
      expect(service.calls.length, 2);
    });

    test('servicio arriba sin ruta: queda el texto neutro', () {
      final c = build(hideInForeground: true, foreground: false);
      c.setServiceRunning(true);
      expect(service.calls, isEmpty);
    });

    test('con el servicio corriendo NO se quita en primer plano', () {
      final c = build(hideInForeground: true, foreground: false);
      c.onStatus(_status());
      c.setServiceRunning(true);
      c.setForeground(true);
      expect(service.calls, ['start', 'update'], reason: 'sin end');
      expect(c.isShown, isTrue);
      // Al bajar el servicio (primer plano) se oculta como siempre.
      c.setServiceRunning(false);
      expect(service.calls.last, 'end');
      expect(c.isShown, isFalse);
    });

    test('el servicio baja en segundo plano: la ruta vuelve como normal', () {
      final c = build(hideInForeground: true, foreground: false);
      c.onStatus(_status());
      c.setServiceRunning(true);
      c.setServiceRunning(false);
      expect(service.calls, ['start', 'update', 'start']);
      expect(c.isShown, isTrue);
    });

    test('ruta terminada con el servicio arriba → end con el estado final', () {
      final c = build(hideInForeground: true, foreground: false);
      c.onStatus(_status());
      c.setServiceRunning(true);
      c.onStatus(_status(stopId: '', state: RouteLiveState.finished));
      expect(service.calls.last, 'end');
      expect(service.payloads.last!.state, RouteLiveState.finished);
    });
  });

  group('isla: sistema vs DisTrack', () {
    RouteIslandAvailability availability({
      bool system = false,
      bool overlay = false,
    }) => RouteIslandAvailability(
      promotion: system
          ? const LiveUpdatesPromotionStatus(
              sdk: 36,
              canPostPromoted: true,
              promotable: true,
            )
          : LiveUpdatesPromotionStatus.none,
      overlaySupported: true,
      overlayGranted: overlay,
    );

    test('resolver: una sola isla; con las dos manda la preferencia', () {
      expect(resolveRouteIslandMode(availability(), null), RouteIslandMode.none);
      expect(
        resolveRouteIslandMode(availability(system: true), null),
        RouteIslandMode.system,
      );
      expect(
        resolveRouteIslandMode(availability(overlay: true), null),
        RouteIslandMode.overlay,
      );
      final both = availability(system: true, overlay: true);
      expect(resolveRouteIslandMode(both, null), RouteIslandMode.system);
      expect(
        resolveRouteIslandMode(both, RouteIslandPreference.overlay),
        RouteIslandMode.overlay,
      );
      expect(
        resolveRouteIslandMode(both, RouteIslandPreference.system),
        RouteIslandMode.system,
      );
      // Preferencia "DisTrack" sin permiso → la del sistema.
      expect(
        resolveRouteIslandMode(
          availability(system: true),
          RouteIslandPreference.overlay,
        ),
        RouteIslandMode.system,
      );
    });

    test('isla de DisTrack: solo en segundo plano, sin promoción', () {
      final c = build(hideInForeground: true);
      c.setIslandMode(RouteIslandMode.overlay);
      expect(service.island, ['promote:false']);
      c.onStatus(_status());
      expect(service.island, ['promote:false'], reason: 'app en pantalla');

      c.setForeground(false);
      expect(service.calls, ['start']);
      expect(service.island.last, 'show');
      expect(c.isOverlayShown, isTrue);

      // Mismas fotos y mismo throttling que la notificación.
      now = now.add(const Duration(seconds: 1));
      c.onStatus(_status(stopId: 's3', stopIndex: 3, completed: 2));
      expect(service.lastOverlay!.stopIndex, 3);
      final shows = service.island.where((e) => e == 'show').length;
      now = now.add(const Duration(seconds: 5));
      c.onStatus(
        _status(stopId: 's3', stopIndex: 3, completed: 2, meters: 900),
      );
      expect(
        service.island.where((e) => e == 'show').length,
        shows,
        reason: 'solo distancia antes de 30 s: nada',
      );

      c.setForeground(true);
      expect(service.island.last, 'hide');
      expect(c.isOverlayShown, isFalse);
    });

    test('se quita al terminar la ruta o al cerrar sesión', () {
      final c = build(hideInForeground: true, foreground: false);
      c.setIslandMode(RouteIslandMode.overlay);
      c.onStatus(_status());
      expect(c.isOverlayShown, isTrue);
      c.onStatus(_status(stopId: '', state: RouteLiveState.finished));
      expect(service.island.last, 'hide');

      c.onStatus(_status(stopId: 's9', stopIndex: 4));
      expect(c.isOverlayShown, isTrue);
      c.onStatus(null);
      expect(service.island.last, 'hide');
      expect(c.isOverlayShown, isFalse);
    });

    test('sin permiso (none) o isla del sistema: nunca la pastilla', () {
      final c = build(hideInForeground: true, foreground: false);
      c.onStatus(_status());
      expect(service.island, isEmpty);
      c.setIslandMode(RouteIslandMode.system);
      expect(service.island, isEmpty, reason: 'la promoción ya estaba pedida');
      expect(c.isOverlayShown, isFalse);
    });

    test('de DisTrack a sistema: re-publica con promoción y quita la pastilla', () {
      final c = build(hideInForeground: true, foreground: false);
      c.setIslandMode(RouteIslandMode.overlay);
      c.onStatus(_status());
      c.setIslandMode(RouteIslandMode.system);
      expect(service.island, ['promote:false', 'show', 'promote:true', 'hide']);
      expect(service.calls, ['start', 'update']);
    });

    test('iOS (sin hideInForeground): la pastilla nunca aparece', () {
      final c = build(foreground: false);
      c.setIslandMode(RouteIslandMode.overlay);
      c.onStatus(_status());
      expect(service.island, ['promote:false']);
      expect(c.isOverlayShown, isFalse);
    });
  });
}
