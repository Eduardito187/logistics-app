import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/printer_credentials.dart';
import 'package:logistics_app/core/printing/printer_credentials_store.dart';
import 'package:logistics_app/core/printing/printer_detection.dart';
import 'package:logistics_app/core/printing/printer_profile_detector.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_controllers.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/printer_setup_screen.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_access_section.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_section.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_extra_networks.dart';

import '../../../../core/auth/test_fakes.dart';
import '../../../../support/app_icon_finders.dart';
import '../../../../support/button_finders.dart';
import '../../../../support/fake_label_printer.dart';
import '../../../../support/fake_printer_profile_detector.dart';
import '../../../../support/screen_sizes.dart';

// Tarjeta "Impresora" (estado primero): vacía → "Conectar impresora"; activa
// → nombre, resumen, estado, "Imprimir prueba" y "Cambiar"; lo técnico en
// "Opciones avanzadas" colapsadas. El core de impresión es un falso.

const _me = AppMeResponse(
  user: AppUserProfile(id: 1, name: 'Juan', email: 'j@x.com', roles: []),
  device: null,
  abilities: [],
);

const _zebraWifi = PrinterConfig(
  transport: PrinterTransport.wifi,
  address: '192.168.2.50:9100',
  label: 'Zebra ZD421',
);

const _ricoh = PrinterConfig(
  transport: PrinterTransport.wifi,
  address: '192.168.2.154:9100',
  label: 'RICOH IM 550',
  language: PrinterLanguage.office,
  protocol: PrinterProtocol.ipp,
);

const _bluetooth = PrinterConfig(
  transport: PrinterTransport.bluetooth,
  address: 'AA:BB:CC',
  label: 'Zebra ZQ630',
);

class _Harness {
  _Harness({FakeLabelPrinter? printer, FakePrinterProfileDetector? detector})
    : printer = printer ?? FakeLabelPrinter(),
      detector = detector ?? FakePrinterProfileDetector();

  final FakeLabelPrinter printer;
  final FakePrinterProfileDetector detector;
  final FakeSecureStorage storage = FakeSecureStorage();
}

Future<_Harness> _pump(
  WidgetTester tester, {
  PrinterConfig? selected,
  _Harness? harness,
  double textScale = 1,
  bool settle = true,
}) async {
  final h = harness ?? _Harness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        labelPrinterProvider.overrideWithValue(h.printer),
        printerProfileDetectorProvider.overrideWithValue(h.detector),
        secureStorageProvider.overrideWithValue(h.storage),
        selectedPrinterProvider.overrideWith((ref) async => selected),
        appMeProvider.overrideWith((ref) async => _me),
        for (final t in PrinterTransport.values)
          discoveredPrintersProvider(t).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        home: withTextScale(
          const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: PrinterSection(defaultUser: 'jperez'),
            ),
          ),
          scale: textScale,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
  return h;
}

Future<void> _openAdvanced(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Opciones avanzadas'));
  await tester.tap(find.text('Opciones avanzadas'));
  await tester.pumpAndSettle();
}

/// Deja vencer los avisos.
Future<void> _finish(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 5));

void main() {
  group('sin impresora', () {
    testWidgets('estado vacío con un solo botón "Conectar impresora"', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Impresora'), findsOneWidget);
      expect(find.text('Todavía no hay impresora'), findsOneWidget);
      expect(find.text('Sin configurar'), findsOneWidget);
      expect(
        findButtonWithText<FilledButton>('Conectar impresora'),
        findsOneWidget,
      );
      // Nada técnico ni de prueba a la vista.
      expect(find.text('Imprimir prueba'), findsNothing);
      expect(find.text('Opciones avanzadas'), findsNothing);
      expect(find.text('Bluetooth'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('"Conectar impresora" abre el asistente en el paso 1', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Conectar impresora'));
      await tester.pumpAndSettle();

      expect(find.byType(PrinterSetupScreen), findsOneWidget);
      expect(find.text('¿Cómo se conecta?'), findsOneWidget);
      expect(find.text('Paso 1 de 3'), findsOneWidget);
    });
  });

  group('con impresora activa', () {
    testWidgets('muestra nombre, resumen sin jerga, estado y dos botones', (
      tester,
    ) async {
      await _pump(tester, selected: _zebraWifi);

      expect(find.text('Zebra ZD421'), findsOneWidget);
      expect(find.text('Zebra · WiFi · 192.168.2.50'), findsOneWidget);
      expect(find.text('Lista'), findsOneWidget);
      expect(
        findButtonWithText<FilledButton>('Imprimir prueba'),
        findsOneWidget,
      );
      expect(findButtonWithText<OutlinedButton>('Cambiar'), findsOneWidget);
      expect(findAppIcon(AppIcon.wifi), findsOneWidget);
      // Sin jerga en la vista principal.
      expect(find.textContaining('IPP'), findsNothing);
      expect(find.textContaining('9100'), findsNothing);
    });

    testWidgets('resumen de oficina', (tester) async {
      await _pump(tester, selected: _ricoh);
      expect(find.text('Oficina · WiFi · 192.168.2.154'), findsOneWidget);
    });

    testWidgets('resumen de Bluetooth', (tester) async {
      await _pump(tester, selected: _bluetooth);
      expect(find.text('Zebra · Bluetooth'), findsOneWidget);
      expect(findAppIcon(AppIcon.bluetooth), findsOneWidget);
    });

    testWidgets('"Cambiar" abre el asistente', (tester) async {
      await _pump(tester, selected: _zebraWifi);

      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();

      expect(find.byType(PrinterSetupScreen), findsOneWidget);
    });
  });

  group('Imprimir prueba', () {
    testWidgets('mientras imprime: deshabilitado y el ícono anima', (
      tester,
    ) async {
      final h = _Harness()..printer.hold = Completer<void>();
      await _pump(tester, selected: _zebraWifi, harness: h);

      await tester.tap(find.text('Imprimir prueba'));
      await tester.pump();

      expect(
        find.descendant(
          of: findButtonWithText<FilledButton>('Imprimir prueba'),
          matching: findAppIconInState(AppIcon.printing, AppIconState.loading),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              findButtonWithText<FilledButton>('Imprimir prueba'),
            )
            .onPressed,
        isNull,
      );

      h.printer.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(h.printer.prints, 1);
      expect(findAppIconInState(AppIcon.printing, AppIconState.idle), findsOne);
      await _finish(tester);
    });

    testWidgets('muestra el resultado debajo, en una línea con ícono', (
      tester,
    ) async {
      final h = await _pump(tester, selected: _zebraWifi);

      await tester.tap(find.text('Imprimir prueba'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(h.printer.lastZpl, contains('Prueba DisTrack'));
      expect(h.printer.lastJobName, 'Prueba DisTrack');
      // Aviso + resultado fijo en la tarjeta.
      expect(find.text('Etiqueta de prueba enviada.'), findsNWidgets(2));
      expect(
        findAppIconInState(AppIcon.success, AppIconState.success),
        findsOne,
      );
      expect(find.text('Lista'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('si falla: motivo en rojo y estado "No responde"', (
      tester,
    ) async {
      await _pump(
        tester,
        selected: _zebraWifi,
        harness: _Harness(
          printer: FakeLabelPrinter(
            printError: const PrinterException('La impresora no responde.'),
          ),
        ),
      );

      await tester.tap(find.text('Imprimir prueba'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('La impresora no responde.'), findsNWidgets(2));
      expect(find.text('No responde'), findsOneWidget);
      expect(find.text('Lista'), findsNothing);
      await _finish(tester);
    });

    testWidgets('IPP retenido: lo dice tal cual (seguimiento del trabajo)', (
      tester,
    ) async {
      await _pump(
        tester,
        selected: _ricoh,
        harness: _Harness(
          printer: FakeLabelPrinter(outcome: const PrintOutcome.held(jobId: 7)),
        ),
      );

      await tester.tap(find.text('Imprimir prueba'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('retuvo el trabajo (#7)'), findsNWidgets(2));
      await _finish(tester);
    });
  });

  group('Opciones avanzadas', () {
    testWidgets('colapsadas por defecto: nada técnico a la vista', (
      tester,
    ) async {
      await _pump(tester, selected: _ricoh);

      expect(find.text('Opciones avanzadas'), findsOneWidget);
      expect(find.byType(PrinterAccessSection), findsNothing);
      expect(find.byType(WifiExtraNetworks), findsNothing);
      expect(find.text('Olvidar impresora'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(RadioListTile<PrinterLanguage>), findsNothing);
    });

    testWidgets('WiFi: al abrir muestra tipo, envío, acceso, redes y olvidar', (
      tester,
    ) async {
      await _pump(tester, selected: _ricoh);
      await _openAdvanced(tester);

      expect(find.byType(PrinterAccessSection), findsOneWidget);
      expect(find.text('Tipo de impresora'), findsOneWidget);
      expect(find.text('Dominio (opcional)'), findsOneWidget);
      expect(find.text('Código de usuario (opcional, Ricoh)'), findsOneWidget);
      expect(find.byType(WifiExtraNetworks), findsOneWidget);
      expect(find.text('Olvidar impresora'), findsOneWidget);
    });

    testWidgets('Bluetooth: solo "Olvidar impresora"', (tester) async {
      await _pump(tester, selected: _bluetooth);
      await _openAdvanced(tester);

      expect(find.byType(PrinterAccessSection), findsNothing);
      expect(find.byType(WifiExtraNetworks), findsNothing);
      expect(find.text('Olvidar impresora'), findsOneWidget);
    });

    testWidgets('cambiar el tipo guarda el perfil y avisa', (tester) async {
      final h = await _pump(tester, selected: _zebraWifi);
      await _openAdvanced(tester);

      await tester.ensureVisible(find.text('Impresora de oficina (PDF)'));
      await tester.tap(find.text('Impresora de oficina (PDF)'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(h.printer.selections.single.language, PrinterLanguage.office);
      expect(h.printer.selections.single.protocol, PrinterProtocol.ipp);
      expect(find.textContaining('Impresora guardada:'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('"Detectar tipo" consulta la IP y muestra el resumen', (
      tester,
    ) async {
      final h = _Harness(
        detector: FakePrinterProfileDetector(
          const PrinterDetection(
            ippAvailable: true,
            makeAndModel: 'RICOH IM 550',
            requiresCredentials: true,
            language: PrinterLanguage.office,
            protocol: PrinterProtocol.ipp,
          ),
        ),
      );
      await _pump(tester, selected: _zebraWifi, harness: h);
      await _openAdvanced(tester);

      await tester.ensureVisible(find.text('Detectar tipo de impresora'));
      await tester.tap(find.text('Detectar tipo de impresora'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(h.detector.hosts, ['192.168.2.50']);
      expect(
        find.textContaining('RICOH IM 550: impresora de oficina'),
        findsOne,
      );
      expect(h.printer.selections.last.language, PrinterLanguage.office);
    });

    testWidgets('"Olvidar impresora" pide confirmación y borra todo', (
      tester,
    ) async {
      final h = _Harness();
      h.storage.seed(LabelPrinter.selectedKey, _ricoh.encode());
      await PrinterCredentialsStore(
        h.storage,
      ).write(_ricoh.address, const PrinterCredentials(username: 'jperez'));
      await _pump(tester, selected: _ricoh, harness: h);
      await _openAdvanced(tester);

      await tester.ensureVisible(find.text('Olvidar impresora'));
      await tester.tap(find.text('Olvidar impresora'));
      await tester.pumpAndSettle();
      expect(find.text('¿Olvidar impresora?'), findsOneWidget);

      // Cancelar no borra.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(h.storage.data[LabelPrinter.selectedKey], isNotNull);

      await tester.tap(find.text('Olvidar impresora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Olvidar'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(h.storage.data[LabelPrinter.selectedKey], isNull);
      expect(
        h.storage.data[PrinterCredentialsStore.keyFor(_ricoh.address)],
        isNull,
      );
      expect(find.text('Impresora olvidada.'), findsOneWidget);
      await _finish(tester);
    });
  });

  testOnScreens('estado vacío no desborda con letra 1.3', (
    tester,
    screen,
  ) async {
    await _pump(tester, textScale: 1.3);

    expect(find.text('Conectar impresora'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testOnScreens('impresora activa con nombre largo y avanzado abierto (1.3)', (
    tester,
    screen,
  ) async {
    await _pump(
      tester,
      textScale: 1.3,
      selected: const PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.100.254:9100',
        label: 'RICOH IM 550 Oficina Administración Planta Alta — Andén Norte',
        language: PrinterLanguage.office,
        protocol: PrinterProtocol.raw9100,
      ),
    );

    expect(find.text('Imprimir prueba'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    await _openAdvanced(tester);
    expect(find.text(PrinterAccessSection.rawHelpText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
