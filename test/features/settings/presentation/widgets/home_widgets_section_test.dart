import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/home_widgets/home_widget_kind.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_prefs_notifier.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_provider.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_service.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/settings/presentation/widgets/home_widgets_section.dart';

import '../../../../core/auth/test_fakes.dart';
import '../../../../core/home_widgets/fake_home_widgets_service.dart';
import '../../../../support/screen_sizes.dart';

// Ajustes → "Widgets de la pantalla de inicio": solo los widgets del rol;
// Android con switch (y confirmación al apagar) y "Agregar"; iOS sin switch,
// con la explicación; privacidad del cliente solo para el chofer.

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this._initial);

  final Session? _initial;

  @override
  Session? build() => _initial;
}

const _driver = Session(userName: 'chofer', role: UserRole.driver);
const _picker = Session(userName: 'prep', role: UserRole.picker);

Future<(ProviderContainer, FakeHomeWidgetsService)> _pump(
  WidgetTester tester, {
  Session session = _driver,
  bool pinSupported = true,
  double textScale = 1.0,
}) async {
  final service = FakeHomeWidgetsService(pinSupported: pinSupported);
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(() => _TestSessionNotifier(session)),
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      homeWidgetsServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(container.dispose);
  // Como en app.dart: el arranque de los widgets vive toda la app.
  container.listen(homeWidgetsProvider, (_, _) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => withTextScale(child!, scale: textScale),
        home: const Scaffold(
          body: SingleChildScrollView(child: HomeWidgetsSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, service);
}

Finder _switchOf(HomeWidgetKind kind) =>
    find.byKey(Key('homeWidgetSwitch_${kind.backendKey}'));

Finder _pinOf(HomeWidgetKind kind) =>
    find.byKey(Key('homeWidgetPin_${kind.backendKey}'));

void main() {
  testWidgets('Android chofer: widgets del rol, switches y Agregar', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Widgets de la pantalla de inicio'), findsOneWidget);
    expect(find.text('Próxima entrega'), findsOneWidget);
    expect(find.text('Mi ruta de hoy'), findsOneWidget);
    expect(find.text('Escanear'), findsOneWidget);
    expect(find.text('Pedidos por preparar'), findsNothing);
    expect(_switchOf(HomeWidgetKind.nextDelivery), findsOneWidget);
    expect(_switchOf(HomeWidgetKind.routeDay), findsOneWidget);
    // "Escanear" va siempre en el selector.
    expect(_switchOf(HomeWidgetKind.quickScan), findsNothing);
    expect(_pinOf(HomeWidgetKind.quickScan), findsOneWidget);
    expect(
      find.byKey(const Key('homeWidgetsHideCustomerSwitch')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('homeWidgetsIosHint')), findsNothing);
  });

  testWidgets('apagar pide confirmación; Cancelar no cambia nada', (
    tester,
  ) async {
    final (container, service) = await _pump(tester);
    final calls = service.enabledCalls.length;
    await tester.ensureVisible(_switchOf(HomeWidgetKind.routeDay));
    await tester.tap(_switchOf(HomeWidgetKind.routeDay));
    await tester.pumpAndSettle();
    expect(find.text(HomeWidgetsSection.disableWarning), findsOneWidget);
    await tester.tap(find.byKey(const Key('homeWidgetDisableCancel')));
    await tester.pumpAndSettle();
    expect(container.read(homeWidgetsPrefsProvider)!.disabledKinds, isEmpty);
    expect(service.enabledCalls.length, calls);
  });

  testWidgets('apagar y confirmar → setEnabledKinds sin ese widget', (
    tester,
  ) async {
    final (container, service) = await _pump(tester);
    await tester.ensureVisible(_switchOf(HomeWidgetKind.routeDay));
    await tester.tap(_switchOf(HomeWidgetKind.routeDay));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('homeWidgetDisableConfirm')));
    await tester.pumpAndSettle();
    expect(container.read(homeWidgetsPrefsProvider)!.disabledKinds, {
      HomeWidgetKind.routeDay,
    });
    expect(service.enabledCalls.last, [
      HomeWidgetKind.nextDelivery,
      HomeWidgetKind.quickScan,
    ]);
    expect(
      tester.widget<SwitchListTile>(_switchOf(HomeWidgetKind.routeDay)).value,
      isFalse,
    );
    expect(_pinOf(HomeWidgetKind.routeDay), findsNothing);

    // Prender de nuevo: sin diálogo.
    await tester.tap(_switchOf(HomeWidgetKind.routeDay));
    await tester.pumpAndSettle();
    expect(find.text(HomeWidgetsSection.disableWarning), findsNothing);
    expect(service.enabledCalls.last, [
      HomeWidgetKind.nextDelivery,
      HomeWidgetKind.routeDay,
      HomeWidgetKind.quickScan,
    ]);
  });

  testWidgets('Agregar a la pantalla de inicio pide el pin', (tester) async {
    final (_, service) = await _pump(tester);
    await tester.ensureVisible(_pinOf(HomeWidgetKind.nextDelivery));
    await tester.tap(_pinOf(HomeWidgetKind.nextDelivery));
    await tester.pumpAndSettle();
    expect(service.pinned, [HomeWidgetKind.nextDelivery]);
  });

  testWidgets('sin soporte de pin no hay botón Agregar', (tester) async {
    await _pump(tester, pinSupported: false);
    expect(_pinOf(HomeWidgetKind.nextDelivery), findsNothing);
  });

  testWidgets('privacidad: ocultar cliente se guarda', (tester) async {
    final (container, _) = await _pump(tester);
    final privacy = find.byKey(const Key('homeWidgetsHideCustomerSwitch'));
    await tester.ensureVisible(privacy);
    await tester.tap(privacy);
    await tester.pumpAndSettle();
    expect(container.read(homeWidgetsPrefsProvider)!.hideCustomer, isTrue);
  });

  testWidgets('preparador: sin privacidad ni widgets del chofer', (
    tester,
  ) async {
    await _pump(tester, session: _picker);
    expect(find.text('Pedidos por preparar'), findsOneWidget);
    expect(find.text('Próxima entrega'), findsNothing);
    expect(
      find.byKey(const Key('homeWidgetsHideCustomerSwitch')),
      findsNothing,
    );
  });

  testWidgets(
    'iOS: sin switch ni Agregar, con la explicación',
    (tester) async {
      await _pump(tester);
      expect(_switchOf(HomeWidgetKind.nextDelivery), findsNothing);
      expect(_switchOf(HomeWidgetKind.routeDay), findsNothing);
      expect(_pinOf(HomeWidgetKind.nextDelivery), findsNothing);
      expect(find.text(HomeWidgetsSection.iosHint), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testOnScreens('sin desbordes con letra 1.3x', (tester, screen) async {
    await _pump(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Widgets de la pantalla de inicio'), findsOneWidget);
  });
}
