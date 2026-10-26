import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/models/app_device_payload.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/api/models/device_list_item.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_controllers.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/devices_screen.dart';
import 'package:logistics_app/features/settings/presentation/settings_screen.dart';
import 'package:logistics_app/features/settings/presentation/widgets/device_card.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_section.dart';

import '../../../support/screen_sizes.dart';

// Layout de Ajustes (perfil, impresora con Bluetooth/WiFi/USB, sesión) y de
// "Mis dispositivos" en los 4 tamaños con letra 1.3x, con textos largos. Un
// desborde hace fallar el test solo.

const _longName = 'María Fernanda de los Ángeles Gutiérrez Quispe';

const _me = AppMeResponse(
  user: AppUserProfile(
    id: 1,
    name: _longName,
    email: 'maria.fernanda.gutierrez.quispe@dismac.com.bo',
    roles: ['chofer', 'preparador', 'supervisor de andén'],
  ),
  device: AppDevicePayload(
    uuid: 'actual',
    platform: 'android',
    name: 'Zebra TC21 del andén principal de Santa Cruz',
    lastSeenAt: null,
  ),
  abilities: [],
);

const _printer = PrinterConfig(
  transport: PrinterTransport.bluetooth,
  address: 'AC:3F:A4:12:34:56',
  label: 'Zebra ZQ520 del camión 12 — andén norte',
);

class _FakeLabelPrinter implements LabelPrinter {
  @override
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {}
  @override
  Future<List<PrinterDevice>> discover(PrinterTransport transport) async =>
      const [];
  @override
  Future<PrinterConfig?> selectedPrinter() async => _printer;
  @override
  Future<void> selectPrinter(PrinterConfig config) async {}
}

DeviceListItem _device(String uuid, {bool revoked = false}) => DeviceListItem(
  uuid: '$uuid-6f1c2a9e-1b7d-4c3e-9a55-0d2e4f6a8b10',
  platform: 'android',
  name: 'Zebra TC21 del andén principal de Santa Cruz',
  lastSeenAt: DateTime(2026, 3, 5, 14, 30),
  revoked: revoked,
);

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, child) => withTextScale(child!),
  home: home,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testOnScreens('ajustes con textos largos e impresora activa (1.3x)', (
    tester,
    screen,
  ) async {
    final container = ProviderContainer(
      overrides: [
        labelPrinterProvider.overrideWithValue(_FakeLabelPrinter()),
        appMeProvider.overrideWith((ref) async => _me),
        selectedPrinterProvider.overrideWith((ref) async => _printer),
        for (final t in PrinterTransport.values)
          discoveredPrintersProvider(t).overrideWith(
            (ref) async => [
              PrinterDevice(
                transport: t,
                address: 'AC:3F:A4:12:34:56',
                name: 'Zebra ZQ520 del camión 12 — andén norte',
              ),
            ],
          ),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).devSignIn(UserRole.supervisor);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Las tres opciones de conexión, y WiFi muestra su formulario.
    await tester.scrollUntilVisible(
      find.text('Imprimir prueba'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Bluetooth'));
    await tester.pumpAndSettle();
    expect(find.text('Bluetooth'), findsOneWidget);
    expect(find.text('USB'), findsOneWidget);
    await tester.tap(find.text('WiFi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('IP de la impresora'));
    await tester.pumpAndSettle();
    expect(find.text('IP de la impresora'), findsOneWidget);
    await tester.ensureVisible(find.text('USB'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USB'));
    await tester.pumpAndSettle();

    // En tablet las secciones no se estiran de borde a borde.
    final section = tester.getRect(find.byType(PrinterSection));
    expect(
      section.width,
      lessThanOrEqualTo(AppBreakpoints.maxContentWidth - 32 + 0.5),
    );

    // Se recorre toda la pantalla (lista perezosa) sin desbordes.
    await tester.scrollUntilVisible(
      find.text('Mis dispositivos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mis dispositivos'), findsOneWidget);
  });

  testOnScreens('mis dispositivos con nombres largos (1.3x)', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          devicesProvider.overrideWith(
            (ref) async => [
              for (var i = 0; i < 12; i++)
                _device(i == 0 ? 'actual' : 'd$i', revoked: i == 2),
            ],
          ),
          appMeProvider.overrideWith(
            (ref) async => const AppMeResponse(
              user: AppUserProfile(
                id: 1,
                name: 'Juan',
                email: 'j@x.com',
                roles: [],
              ),
              device: AppDevicePayload(
                uuid: 'actual-6f1c2a9e-1b7d-4c3e-9a55-0d2e4f6a8b10',
                platform: 'android',
                name: 'Zebra',
                lastSeenAt: null,
              ),
              abilities: [],
            ),
          ),
        ],
        child: _app(const DevicesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Este dispositivo'), findsOneWidget);
    // Lista perezosa: no construye las 12 tarjetas de una.
    if (screen != TestScreen.tabletPortrait) {
      expect(find.byType(DeviceCard).evaluate().length, lessThan(12));
    }
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(find.byType(DeviceCard), findsWidgets);
  });
}
