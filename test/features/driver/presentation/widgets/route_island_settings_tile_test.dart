import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/live_updates/live_updates_promotion.dart';
import 'package:logistics_app/core/live_updates/live_updates_service.dart';
import 'package:logistics_app/core/live_updates/route_island.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_island_settings_tile.dart';

import '../../../../core/auth/test_fakes.dart';

// Fila "Isla de ruta" de Ajustes: estado según lo que soporta el teléfono,
// botones para activar la isla del sistema o permitir la de DisTrack, selector
// cuando están las dos, texto informativo en iOS y oculta para otros roles.

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this._initial);

  final Session? _initial;

  @override
  Session? build() => _initial;
}

/// Canal falso: responde lo configurado y registra lo que se abre.
class _FakeService extends LiveUpdatesService {
  _FakeService({required this.promotion, required this.overlayGranted});

  final LiveUpdatesPromotionStatus promotion;
  final bool overlayGranted;
  final List<String> opened = [];

  @override
  Future<LiveUpdatesPromotionStatus> promotionStatus() async => promotion;

  @override
  Future<({bool supported, bool granted})> overlayStatus() async =>
      (supported: true, granted: overlayGranted);

  @override
  Future<bool> openPromotionSettings() async {
    opened.add('promotion');
    return true;
  }

  @override
  Future<bool> openOverlaySettings() async {
    opened.add('overlay');
    return true;
  }
}

const _promotionActive = LiveUpdatesPromotionStatus(
  sdk: 36,
  canPostPromoted: true,
  promotable: true,
);

const _promotionDenied = LiveUpdatesPromotionStatus(
  sdk: 36,
  canPostPromoted: false,
  promotable: true,
  reasons: ['promotionDenied'],
);

/// Lo que reporta el nativo cuando ya se eligió la isla de DisTrack: la
/// notificación se arma sin pedido de promoción (`promotable: false`), pero el
/// teléfono sigue pudiendo promover (`canPostPromoted`).
const _promotionNotRequested = LiveUpdatesPromotionStatus(
  sdk: 36,
  canPostPromoted: true,
  promotable: false,
  reasons: ['notPromotable'],
);

const _android13 = LiveUpdatesPromotionStatus(sdk: 33, reasons: ['sdk']);

Future<FakeSecureStorage> _pump(
  WidgetTester tester,
  _FakeService service, {
  UserRole role = UserRole.driver,
}) async {
  final storage = FakeSecureStorage();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _TestSessionNotifier(Session(userName: 'chofer', role: role)),
        ),
        liveUpdatesServiceProvider.overrideWithValue(service),
        secureStorageProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: RouteIslandSettingsTile()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return storage;
}

void main() {
  testWidgets('Android 16 con las dos islas: selector, sistema por defecto', (
    tester,
  ) async {
    final storage = await _pump(
      tester,
      _FakeService(promotion: _promotionActive, overlayGranted: true),
    );
    expect(find.text('Isla de ruta'), findsOneWidget);
    expect(find.byKey(const Key('routeIslandSelector')), findsOneWidget);
    expect(find.textContaining('barra de estado del teléfono'), findsOneWidget);
    expect(find.text('Activar en el sistema'), findsNothing);
    expect(find.text('Permitir isla de DisTrack'), findsNothing);

    await tester.tap(find.text('Isla de DisTrack'));
    await tester.pumpAndSettle();
    expect(
      storage.data[RouteIslandPreferenceNotifier.storageKey],
      RouteIslandPreference.overlay.storageValue,
    );
    expect(find.textContaining('isla de DisTrack se ve'), findsOneWidget);

    // Y se puede volver: el selector no queda pegado en la primera elección.
    await tester.tap(find.text('Isla del sistema'));
    await tester.pumpAndSettle();
    expect(
      storage.data[RouteIslandPreferenceNotifier.storageKey],
      RouteIslandPreference.system.storageValue,
    );
    expect(find.textContaining('barra de estado del teléfono'), findsOneWidget);
  });

  testWidgets('con la isla de DisTrack puesta se vuelve a la del sistema', (
    tester,
  ) async {
    // El nativo reporta promotable:false (la notificación va sin pedido de
    // promoción): el selector tiene que seguir ahí y la isla del sistema
    // seguir siendo elegible.
    final storage = await _pump(
      tester,
      _FakeService(promotion: _promotionNotRequested, overlayGranted: true),
    );
    expect(find.byKey(const Key('routeIslandSelector')), findsOneWidget);
    expect(find.text('Isla del sistema'), findsOneWidget);
    expect(find.textContaining('barra de estado del teléfono'), findsOneWidget);

    await tester.tap(find.text('Isla de DisTrack'));
    await tester.pumpAndSettle();
    expect(find.textContaining('isla de DisTrack se ve'), findsOneWidget);

    await tester.tap(find.text('Isla del sistema'));
    await tester.pumpAndSettle();
    expect(
      storage.data[RouteIslandPreferenceNotifier.storageKey],
      RouteIslandPreference.system.storageValue,
    );
    expect(find.textContaining('barra de estado del teléfono'), findsOneWidget);
  });

  testWidgets('Android < 16 sin permiso: desactivada + Permitir isla', (
    tester,
  ) async {
    final service = _FakeService(promotion: _android13, overlayGranted: false);
    await _pump(tester, service);
    expect(find.textContaining('Desactivada'), findsOneWidget);
    expect(find.text('Activar en el sistema'), findsNothing);
    expect(find.byKey(const Key('routeIslandSelector')), findsNothing);

    await tester.tap(find.text('Permitir isla de DisTrack'));
    await tester.pump();
    expect(service.opened, ['overlay']);
  });

  testWidgets('Android < 16 con permiso: se elige "Sin isla" o DisTrack', (
    tester,
  ) async {
    // Sin isla del sistema la pastilla NO es el default (es intrusiva): se
    // elige en el selector, y se puede volver a "Sin isla".
    final storage = await _pump(
      tester,
      _FakeService(promotion: _android13, overlayGranted: true),
    );
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byKey(const Key('routeIslandSelector')), findsOneWidget);
    expect(find.text('Sin isla'), findsOneWidget);
    expect(find.text('Isla del sistema'), findsNothing);
    expect(find.textContaining('Desactivada'), findsOneWidget);

    await tester.tap(find.text('Isla de DisTrack'));
    await tester.pumpAndSettle();
    expect(
      storage.data[RouteIslandPreferenceNotifier.storageKey],
      RouteIslandPreference.overlay.storageValue,
    );
    expect(find.textContaining('isla de DisTrack se ve'), findsOneWidget);

    await tester.tap(find.text('Sin isla'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Desactivada'), findsOneWidget);
  });

  testWidgets('Android 16 con Live updates apagado: Activar en el sistema', (
    tester,
  ) async {
    final service = _FakeService(
      promotion: _promotionDenied,
      overlayGranted: false,
    );
    await _pump(tester, service);
    expect(find.textContaining('Desactivada'), findsOneWidget);

    await tester.tap(find.text('Activar en el sistema'));
    await tester.pump();
    expect(service.opened, ['promotion']);
    expect(find.text('Permitir isla de DisTrack'), findsOneWidget);
  });

  testWidgets('iOS: solo texto informativo, sin controles', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _pump(
        tester,
        _FakeService(promotion: _promotionActive, overlayGranted: true),
      );
      expect(find.textContaining('Dynamic Island'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byKey(const Key('routeIslandSelector')), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('otro rol: no se muestra', (tester) async {
    await _pump(
      tester,
      _FakeService(promotion: _promotionActive, overlayGranted: true),
      role: UserRole.picker,
    );
    expect(find.text('Isla de ruta'), findsNothing);
  });
}
