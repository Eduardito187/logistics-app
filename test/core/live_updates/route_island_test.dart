import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/live_updates/live_updates_promotion.dart';
import 'package:logistics_app/core/live_updates/route_island.dart';

import '../auth/test_fakes.dart';

// Qué isla se usa (sistema / DisTrack / ninguna) y la preferencia del chofer:
// disponibilidad, regla de elección y persistencia de la preferencia.

const _active = LiveUpdatesPromotionStatus(
  sdk: 36,
  canPostPromoted: true,
  promotable: true,
);

/// Lo que reporta el nativo con la isla de DisTrack elegida: la notificación
/// se arma SIN pedido de promoción, así que `promotable` es false aunque el
/// teléfono sí pueda promover.
const _notRequested = LiveUpdatesPromotionStatus(
  sdk: 36,
  canPostPromoted: true,
  promotable: false,
  reasons: ['notPromotable'],
);

/// Android 16 con "Live updates" apagado para la app.
const _denied = LiveUpdatesPromotionStatus(
  sdk: 36,
  canPostPromoted: false,
  promotable: true,
  reasons: ['promotionDenied'],
);

const _android13 = LiveUpdatesPromotionStatus(sdk: 33, reasons: ['sdk']);

ProviderContainer _container(FlutterSecureStorage storage) {
  final container = ProviderContainer(
    overrides: [secureStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('RouteIslandAvailability', () {
    test('isla del sistema disponible con la promoción activa', () {
      const availability = RouteIslandAvailability(promotion: _active);
      expect(availability.systemAvailable, isTrue);
      expect(availability.overlayAvailable, isFalse);
    });

    test('sigue disponible sin pedido de promoción (isla propia elegida)', () {
      const availability = RouteIslandAvailability(promotion: _notRequested);
      expect(availability.systemAvailable, isTrue);
    });

    test(
      'no disponible si el sistema no deja promover, ni en Android < 16',
      () {
        expect(
          const RouteIslandAvailability(promotion: _denied).systemAvailable,
          isFalse,
        );
        expect(
          const RouteIslandAvailability(promotion: _android13).systemAvailable,
          isFalse,
        );
      },
    );

    test('la isla propia necesita soporte y permiso', () {
      expect(
        const RouteIslandAvailability(
          overlaySupported: true,
          overlayGranted: false,
        ).overlayAvailable,
        isFalse,
      );
      expect(
        const RouteIslandAvailability(
          overlaySupported: true,
          overlayGranted: true,
        ).overlayAvailable,
        isTrue,
      );
    });
  });

  group('resolveRouteIslandMode', () {
    const both = RouteIslandAvailability(
      promotion: _active,
      overlaySupported: true,
      overlayGranted: true,
    );
    const onlyOverlay = RouteIslandAvailability(
      promotion: _android13,
      overlaySupported: true,
      overlayGranted: true,
    );

    test('las dos islas: manda la preferencia, default la del sistema', () {
      expect(resolveRouteIslandMode(both, null), RouteIslandMode.system);
      expect(
        resolveRouteIslandMode(both, RouteIslandPreference.system),
        RouteIslandMode.system,
      );
      expect(
        resolveRouteIslandMode(both, RouteIslandPreference.overlay),
        RouteIslandMode.overlay,
      );
    });

    test('ida y vuelta entre las dos islas cuantas veces se quiera', () {
      final modes = [
        RouteIslandPreference.overlay,
        RouteIslandPreference.system,
        RouteIslandPreference.overlay,
      ].map((p) => resolveRouteIslandMode(both, p)).toList();
      expect(modes, [
        RouteIslandMode.overlay,
        RouteIslandMode.system,
        RouteIslandMode.overlay,
      ]);
    });

    test('sin isla del sistema la propia NO es el default', () {
      expect(resolveRouteIslandMode(onlyOverlay, null), RouteIslandMode.none);
      expect(
        resolveRouteIslandMode(onlyOverlay, RouteIslandPreference.system),
        RouteIslandMode.none,
      );
      expect(
        resolveRouteIslandMode(onlyOverlay, RouteIslandPreference.overlay),
        RouteIslandMode.overlay,
      );
    });

    test('sin ninguna: ninguna isla', () {
      expect(
        resolveRouteIslandMode(
          RouteIslandAvailability.none,
          RouteIslandPreference.overlay,
        ),
        RouteIslandMode.none,
      );
    });
  });

  group('RouteIslandPreferenceNotifier', () {
    test('arranca sin preferencia y carga la guardada', () async {
      final storage = FakeSecureStorage()
        ..seed(
          RouteIslandPreferenceNotifier.storageKey,
          RouteIslandPreference.overlay.storageValue,
        );
      final container = _container(storage);
      final sub = container.listen(routeIslandPreferenceProvider, (_, _) {});
      addTearDown(sub.close);
      expect(container.read(routeIslandPreferenceProvider), isNull);
      await _settle();
      expect(
        container.read(routeIslandPreferenceProvider),
        RouteIslandPreference.overlay,
      );
    });

    test('set alterna y persiste las veces que sea', () async {
      final storage = FakeSecureStorage();
      final container = _container(storage);
      final notifier = container.read(routeIslandPreferenceProvider.notifier);

      for (final expected in [
        RouteIslandPreference.overlay,
        RouteIslandPreference.system,
        RouteIslandPreference.overlay,
      ]) {
        await notifier.set(expected);
        expect(container.read(routeIslandPreferenceProvider), expected);
        expect(
          storage.data[RouteIslandPreferenceNotifier.storageKey],
          expected.storageValue,
        );
      }
    });

    test('la elección del chofer gana a una carga lenta', () async {
      final storage = FakeSecureStorage()
        ..seed(
          RouteIslandPreferenceNotifier.storageKey,
          RouteIslandPreference.overlay.storageValue,
        );
      final container = _container(storage);
      final sub = container.listen(routeIslandPreferenceProvider, (_, _) {});
      addTearDown(sub.close);
      await container
          .read(routeIslandPreferenceProvider.notifier)
          .set(RouteIslandPreference.system);
      await _settle();
      expect(
        container.read(routeIslandPreferenceProvider),
        RouteIslandPreference.system,
      );
    });
  });
}
