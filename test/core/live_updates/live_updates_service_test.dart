import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/live_updates/live_updates_promotion.dart';
import 'package:logistics_app/core/live_updates/live_updates_service.dart';
import 'package:logistics_app/core/live_updates/live_updates_support.dart';
import 'package:logistics_app/core/live_updates/route_live_state.dart';
import 'package:logistics_app/core/live_updates/route_live_status.dart';

RouteLiveStatus _status() => RouteLiveStatus(
  routeId: 'r1',
  stopId: 's3',
  stopIndex: 3,
  stopCount: 8,
  completedCount: 2,
  customer: 'Juan Pérez',
  state: RouteLiveState.onTheWay,
  etaAt: DateTime(2026, 11, 11, 14, 20),
  remainingMeters: 2300,
  lat: -17.78,
  lng: -63.18,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = LiveUpdatesService.defaultChannel;
  late TestDefaultBinaryMessenger messenger;
  late List<MethodCall> calls;

  setUp(() {
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    calls = [];
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  void answer(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  test('start/update/end usan el canal con el mapa del estado', () async {
    answer((_) => true);
    const service = LiveUpdatesService();
    final status = _status();

    expect(await service.start(status), isTrue);
    expect(await service.update(status), isTrue);
    expect(await service.end(), isTrue);

    expect(calls.map((c) => c.method), ['start', 'update', 'end']);
    final args = calls.first.arguments as Map;
    expect(args['stopIndex'], 3);
    expect(args['stopCount'], 8);
    expect(args['completed'], 2);
    expect(args['status'], 'on_the_way');
    expect(args['customer'], 'Juan Pérez');
    expect(args['title'], 'Parada 3 de 8 · Llega 14:20');
    expect(args['chip'], '14:20');
    expect(args['subText'], 'A 2,3 km');
    expect(args['lat'], -17.78);
    expect(args['progress'], closeTo(0.25, 1e-9));
    expect(calls.last.arguments, isNull);
  });

  test('end con estado final lo manda (iOS lo deja unos minutos)', () async {
    answer((_) => true);
    await const LiveUpdatesService().end(_status());
    expect((calls.single.arguments as Map)['routeId'], 'r1');
  });

  test('sin plugin (MissingPluginException) es no-op silencioso', () async {
    // Sin handler registrado el canal lanza MissingPluginException.
    const service = LiveUpdatesService();
    expect(await service.start(_status()), isFalse);
    expect(await service.update(_status()), isFalse);
    expect(await service.end(), isFalse);
    expect(await service.isSupported(), same(LiveUpdatesSupport.none));
  });

  test('error del nativo no se propaga', () async {
    answer((_) => throw PlatformException(code: 'live_updates'));
    expect(await const LiveUpdatesService().start(_status()), isFalse);
  });

  test('isSupported lee android/ios', () async {
    answer(
      (_) => {
        'android': {'promoted': true, 'sdk': 36},
        'ios': {'liveActivities': false},
      },
    );
    final support = await const LiveUpdatesService().isSupported();
    expect(support.androidPromoted, isTrue);
    expect(support.androidSdk, 36);
    expect(support.iosLiveActivities, isFalse);
  });

  test('isSupported tolera mapas incompletos', () {
    final support = LiveUpdatesSupport.fromMap({
      'ios': {'liveActivities': true},
      'android': 'x',
    });
    expect(support.iosLiveActivities, isTrue);
    expect(support.androidPromoted, isFalse);
    expect(support.androidSdk, 0);
  });

  test('promotionStatus: activo, apagado por el usuario, no disponible', () async {
    answer(
      (_) => {
        'sdk': 36,
        'canPostPromoted': true,
        'promotable': true,
        'reasons': <String>[],
      },
    );
    final active = await const LiveUpdatesService().promotionStatus();
    expect(calls.single.method, 'promotionStatus');
    expect(active.state, LiveUpdatesPromotionState.active);

    final denied = LiveUpdatesPromotionStatus.fromMap({
      'sdk': 36,
      'canPostPromoted': false,
      'promotable': true,
      'reasons': ['promotionDenied'],
    });
    expect(denied.state, LiveUpdatesPromotionState.disabledBySystem);

    final oem = LiveUpdatesPromotionStatus.fromMap({
      'sdk': 36,
      'canPostPromoted': true,
      'promotable': false,
      'reasons': ['notPromotable'],
    });
    expect(oem.state, LiveUpdatesPromotionState.unavailable);

    final old = LiveUpdatesPromotionStatus.fromMap({
      'sdk': 34,
      'reasons': ['sdk'],
    });
    expect(old.state, LiveUpdatesPromotionState.unsupported);
    expect(
      LiveUpdatesPromotionStatus.fromMap({'sdk': 'x', 'reasons': 'y'}).state,
      LiveUpdatesPromotionState.unsupported,
    );
  });

  test('isla de DisTrack y promoción usan sus métodos del canal', () async {
    answer((call) {
      if (call.method == 'overlayStatus') {
        return {'supported': true, 'granted': false};
      }
      return true;
    });
    const service = LiveUpdatesService();
    final overlay = await service.overlayStatus();
    expect(overlay.supported, isTrue);
    expect(overlay.granted, isFalse);
    expect(await service.showOverlay(_status()), isTrue);
    expect(await service.hideOverlay(), isTrue);
    expect(await service.setPromotionEnabled(false), isTrue);
    expect(await service.openOverlaySettings(), isTrue);
    expect(await service.openPromotionSettings(), isTrue);
    expect(calls.map((c) => c.method), [
      'overlayStatus',
      'overlayShow',
      'overlayHide',
      'setPromotionEnabled',
      'openOverlaySettings',
      'openPromotionSettings',
    ]);
    expect((calls[1].arguments as Map)['stopIndex'], 3);
    expect(calls[3].arguments, {'enabled': false});
  });

  test('sin plugin: isla y promoción son no-op', () async {
    const service = LiveUpdatesService();
    expect(await service.overlayStatus(), (supported: false, granted: false));
    expect(await service.showOverlay(_status()), isFalse);
    expect(
      await service.promotionStatus(),
      same(LiveUpdatesPromotionStatus.none),
    );
  });
}
