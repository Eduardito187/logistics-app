import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/printer_credentials_store.dart';
import 'package:logistics_app/core/printing/printer_detection.dart';
import 'package:logistics_app/core/printing/printer_profile_detector.dart';
import 'package:logistics_app/core/printing/scanned_network.dart';
import 'package:logistics_app/core/printing/wifi_printer_hit.dart';
import 'package:logistics_app/core/printing/wifi_printer_scanner.dart';
import 'package:logistics_app/core/printing/wifi_scan_progress.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_controllers.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/printer_setup_screen.dart';
import 'package:logistics_app/features/settings/presentation/widgets/non_zebra_printer_dialog.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_credentials_prompt.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_option_card.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_extra_networks.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_printer_form.dart';

import '../../../core/auth/test_fakes.dart';
import '../../../support/button_finders.dart';
import '../../../support/fake_label_printer.dart';
import '../../../support/fake_printer_profile_detector.dart';
import '../../../support/fake_wifi_printer_scanner.dart';
import '../../../support/screen_sizes.dart';

// Asistente "Conectar impresora": 1) ¿Cómo se conecta? 2) Elegí 3) Listo.
// Escáner WiFi, detector, impresora y almacén son falsos (sin red ni
// hardware).

const _me = AppMeResponse(
  user: AppUserProfile(id: 1, name: 'Juan', email: 'j@x.com', roles: []),
  device: null,
  abilities: [],
);

const _btZebra = PrinterDevice(
  transport: PrinterTransport.bluetooth,
  address: 'AA:BB:CC',
  name: 'Zebra ZQ630',
);

const _zebraHit = WifiPrinterHit(
  host: '192.168.1.40',
  port: 9100,
  name: 'Zebra ZD421',
  isZebra: true,
);
const _unknownHit = WifiPrinterHit(host: '192.168.1.77', port: 9100);
const _ricohHit = WifiPrinterHit(
  host: '192.168.2.154',
  port: 9100,
  name: 'RICOH IM 550',
);

const _officeNeedsUser = PrinterDetection(
  ippAvailable: true,
  makeAndModel: 'RICOH IM 550',
  requiresCredentials: true,
  language: PrinterLanguage.office,
  protocol: PrinterProtocol.ipp,
);

const _zebraDetected = PrinterDetection(
  makeAndModel: 'Zebra ZD421',
  isZebra: true,
  language: PrinterLanguage.zpl,
  protocol: PrinterProtocol.raw9100,
);

WifiScanProgress _found(List<WifiPrinterHit> hits, {bool done = true}) =>
    WifiScanProgress(
      scanned: done ? 253 : 100,
      total: 253,
      found: hits,
      networks: const [ScannedNetwork(label: '192.168.1.0/24')],
      done: done,
    );

class _Harness {
  _Harness({PrinterDetection detection = PrinterDetection.unknown})
    : detector = FakePrinterProfileDetector(detection);

  final FakeLabelPrinter printer = FakeLabelPrinter();
  final FakePrinterProfileDetector detector;
  final FakeWifiPrinterScanner scanner = FakeWifiPrinterScanner();
  final FakeSecureStorage storage = FakeSecureStorage();
}

Future<_Harness> _pump(
  WidgetTester tester, {
  _Harness? harness,
  double textScale = 1,
  List<PrinterDevice> bluetooth = const [_btZebra],
}) async {
  final h = harness ?? _Harness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        labelPrinterProvider.overrideWithValue(h.printer),
        printerProfileDetectorProvider.overrideWithValue(h.detector),
        wifiPrinterScannerProvider.overrideWithValue(h.scanner),
        secureStorageProvider.overrideWithValue(h.storage),
        selectedPrinterProvider.overrideWith((ref) async => null),
        appMeProvider.overrideWith((ref) async => _me),
        discoveredPrintersProvider(
          PrinterTransport.bluetooth,
        ).overrideWith((ref) async => bluetooth),
        discoveredPrintersProvider(
          PrinterTransport.usb,
        ).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        home: withTextScale(
          const PrinterSetupScreen(defaultUser: 'jperez'),
          scale: textScale,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

/// Paso 1 → WiFi; la búsqueda arranca sola en el frame siguiente.
Future<void> _enterWifi(WidgetTester tester) async {
  await tester.tap(find.text('WiFi'));
  await tester.pump();
  await tester.pump();
}

/// Varios frames cortos (guardar + detectar son varias esperas encadenadas).
Future<void> _settleShort(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Lleva [finder] a la vista y deja un frame para que el scroll se aplique
/// (`ensureVisible` solo mueve la posición; sin `pump` el tap usa la
/// posición vieja y cae fuera de pantalla).
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// Deja vencer los avisos.
Future<void> _finish(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 5));

void main() {
  testWidgets('paso 1: tres tarjetas grandes, una decisión', (tester) async {
    await _pump(tester);

    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(find.text('¿Cómo se conecta?'), findsOneWidget);
    expect(find.byType(PrinterOptionCard), findsNWidgets(3));
    expect(find.text('Bluetooth'), findsOneWidget);
    expect(find.text('Zebra portátil'), findsOneWidget);
    expect(find.text('WiFi'), findsOneWidget);
    expect(find.text('Impresora de red'), findsOneWidget);
    expect(find.text('Cable USB'), findsOneWidget);
    // Nada de segmentados ni campos.
    expect(find.byType(SegmentedButton<PrinterTransport>), findsNothing);
    expect(find.byType(TextField), findsNothing);
    // Tarjetas táctiles grandes (≥ 72 dp).
    for (var i = 0; i < 3; i++) {
      expect(
        tester.getSize(find.byType(PrinterOptionCard).at(i)).height,
        greaterThanOrEqualTo(72),
      );
    }
  });

  group('Bluetooth / USB', () {
    testWidgets('Bluetooth lista las emparejadas con "Buscar de nuevo"', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();

      expect(find.text('Paso 2 de 3'), findsOneWidget);
      expect(find.text('Zebra ZQ630'), findsOneWidget);
      expect(find.text('AA:BB:CC'), findsOneWidget);
      expect(
        findButtonWithText<OutlinedButton>('Buscar de nuevo'),
        findsOneWidget,
      );
    });

    testWidgets('tocar una la guarda, avisa y pasa a "Listo" sin pedir nada', (
      tester,
    ) async {
      final h = await _pump(tester);

      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zebra ZQ630'));
      await _settleShort(tester);

      expect(h.printer.selections.single.address, 'AA:BB:CC');
      expect(
        find.text('Impresora guardada: Zebra ZQ630 (AA:BB:CC).'),
        findsOneWidget,
      );
      expect(find.text('Paso 3 de 3'), findsOneWidget);
      expect(find.text('¡Impresora conectada!'), findsOneWidget);
      expect(find.text('Zebra · Bluetooth'), findsOneWidget);
      expect(find.byType(PrinterCredentialsPrompt), findsNothing);
      expect(h.detector.hosts, isEmpty); // Bluetooth no se detecta
      await _finish(tester);
    });

    testWidgets('USB vacío: explica qué hacer', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Cable USB'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No hay impresoras USB conectadas'),
        findsOneWidget,
      );
    });

    testWidgets('atrás desde el paso 2 vuelve al paso 1', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 de 3'), findsOneWidget);
    });
  });

  group('WiFi', () {
    testWidgets('al entrar la búsqueda arranca sola y lista en vivo', (
      tester,
    ) async {
      final h = await _pump(tester);
      expect(h.scanner.scans, 0); // no busca antes de elegir WiFi

      await _enterWifi(tester);
      expect(h.scanner.scans, 1);

      h.scanner.emit(_found(const [_zebraHit], done: false));
      await tester.pump();

      expect(find.text('Zebra ZD421'), findsOneWidget);
      expect(find.text('Buscando impresoras… 40% · 1 encontrada'), findsOne);
      // La ayuda manual está escondida: solo el enlace.
      expect(find.text('¿No aparece? Ingresar IP'), findsOneWidget);
      expect(find.byType(WifiPrinterForm), findsNothing);
      expect(find.byType(WifiExtraNetworks), findsNothing);
    });

    testWidgets('salir del paso WiFi cancela la búsqueda', (tester) async {
      final h = await _pump(tester);
      await _enterWifi(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump();

      expect(h.scanner.cancelled, isTrue);
      expect(find.text('Paso 1 de 3'), findsOneWidget);
    });

    testWidgets('elegir una encontrada la guarda, avisa y detecta su tipo', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        harness: _Harness(detection: _zebraDetected),
      );
      await _enterWifi(tester);
      h.scanner.emit(_found(const [_zebraHit]));
      await tester.pump();

      await tester.tap(find.text('Zebra ZD421'));
      await _settleShort(tester);

      expect(h.printer.selections.first.address, '192.168.1.40:9100');
      expect(
        find.text('Impresora guardada: Zebra ZD421 (192.168.1.40:9100).'),
        findsOneWidget,
      );
      expect(h.detector.hosts, ['192.168.1.40']);
      expect(find.text('¡Impresora conectada!'), findsOneWidget);
      // Zebra: no se pide nada.
      expect(find.byType(PrinterCredentialsPrompt), findsNothing);
      expect(
        findButtonWithText<FilledButton>('Imprimir prueba'),
        findsOneWidget,
      );
      await _finish(tester);
    });

    testWidgets('no Zebra: pide confirmación; Cancelar no guarda', (
      tester,
    ) async {
      final h = await _pump(tester);
      await _enterWifi(tester);
      h.scanner.emit(_found(const [_ricohHit]));
      await tester.pump();

      await tester.tap(find.text('RICOH IM 550'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NonZebraPrinterDialog), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(h.printer.selections, isEmpty);
      expect(find.text('Paso 2 de 3'), findsOneWidget);
    });

    testWidgets('"¿No aparece? Ingresar IP" muestra el formulario y la ayuda', (
      tester,
    ) async {
      await _pump(tester);
      await _enterWifi(tester);

      await tester.tap(find.text('¿No aparece? Ingresar IP'));
      await tester.pump();

      expect(find.byType(WifiPrinterForm), findsOneWidget);
      expect(find.text('IP de la impresora'), findsOneWidget);
      expect(find.text('Probar conexión'), findsOneWidget);
      // "Buscar en otra red" sigue escondido hasta que se pida.
      expect(find.byType(WifiExtraNetworks), findsNothing);

      await _scrollTo(tester, find.text('Buscar en otra red'));
      await tester.tap(find.text('Buscar en otra red'));
      await tester.pump();
      expect(find.byType(WifiExtraNetworks), findsOneWidget);
    });

    testWidgets('IP a mano: "Probar conexión" diagnostica', (tester) async {
      await _pump(tester);
      await _enterWifi(tester);
      await tester.tap(find.text('¿No aparece? Ingresar IP'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'IP de la impresora'),
        '192.168.1.60',
      );
      await _scrollTo(tester, find.text('Probar conexión'));
      await tester.tap(find.text('Probar conexión'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.text('La impresora responde en 192.168.1.60:9100.'),
        findsOneWidget,
      );
    });

    testWidgets('IP a mano: guardar avisa y pasa a "Listo"', (tester) async {
      final h = await _pump(tester);
      await _enterWifi(tester);
      await tester.tap(find.text('¿No aparece? Ingresar IP'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'IP de la impresora'),
        '192.168.1.60',
      );
      await _scrollTo(tester, find.text('Guardar impresora WiFi'));
      await tester.tap(find.text('Guardar impresora WiFi'));
      await _settleShort(tester);

      expect(h.printer.selections.single.address, '192.168.1.60:9100');
      expect(
        find.text('Impresora guardada: WiFi 192.168.1.60 (192.168.1.60:9100).'),
        findsOneWidget,
      );
      expect(find.text('¡Impresora conectada!'), findsOneWidget);
      await _finish(tester);
    });
  });

  group('paso Listo', () {
    Future<_Harness> chooseUnknown(WidgetTester tester, _Harness h) async {
      await _pump(tester, harness: h);
      await _enterWifi(tester);
      h.scanner.emit(_found(const [_unknownHit]));
      await tester.pump();
      await tester.tap(find.text('Impresora de red'));
      await _settleShort(tester);
      return h;
    }

    testWidgets('si la detección exige usuario: SOLO usuario y contraseña', (
      tester,
    ) async {
      final h = await chooseUnknown(
        tester,
        _Harness(detection: _officeNeedsUser),
      );

      expect(find.text('Esta impresora pide tu usuario'), findsOneWidget);
      expect(find.byType(PrinterCredentialsPrompt), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Usuario'))
            .controller!
            .text,
        'jperez',
      );
      expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
      // Nada de dominio, código ni protocolo en este paso.
      expect(find.textContaining('Dominio'), findsNothing);
      expect(find.textContaining('Código de usuario'), findsNothing);
      expect(find.textContaining('IPP'), findsNothing);
      // Se guardó el perfil detectado (oficina por IPP).
      expect(h.printer.selections.last.language, PrinterLanguage.office);
      await _finish(tester);
    });

    testWidgets('"Guardar y probar" guarda el acceso e imprime la prueba', (
      tester,
    ) async {
      final h = await chooseUnknown(
        tester,
        _Harness(detection: _officeNeedsUser),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Contraseña'),
        's3cr3t',
      );
      await _scrollTo(tester, find.text('Guardar y probar'));
      await tester.tap(find.text('Guardar y probar'));
      await _settleShort(tester);

      final stored = await PrinterCredentialsStore(
        h.storage,
      ).read('192.168.1.77:9100');
      expect(stored?.username, 'jperez');
      expect(stored?.password, 's3cr3t');
      expect(h.printer.prints, 1);
      expect(find.text('Etiqueta de prueba enviada.'), findsWidgets);
      await _finish(tester);
    });

    testWidgets('sin identificar: no pide usuario', (tester) async {
      await chooseUnknown(tester, _Harness());

      expect(find.byType(PrinterCredentialsPrompt), findsNothing);
      expect(find.text('Imprimir prueba'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('"Imprimir prueba" muestra el resultado en el paso', (
      tester,
    ) async {
      final h = await chooseUnknown(tester, _Harness());

      await tester.tap(find.text('Imprimir prueba'));
      // El aviso de la prueba reemplaza al de "guardada": primero sale el
      // anterior (animación) y recién después entra el nuevo.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(h.printer.prints, 1);
      // Aviso + resultado fijo en el paso.
      expect(find.text('Etiqueta de prueba enviada.'), findsNWidgets(2));
      expect(find.text('Terminar'), findsOneWidget);
      await _finish(tester);
    });
  });

  group('no desborda (letra 1.3)', () {
    testOnScreens('paso 1', (tester, screen) async {
      await _pump(tester, textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testOnScreens('paso 2 Bluetooth con nombres largos', (
      tester,
      screen,
    ) async {
      await _pump(
        tester,
        textScale: 1.3,
        bluetooth: const [
          PrinterDevice(
            transport: PrinterTransport.bluetooth,
            address: 'AC:3F:A4:12:34:56',
            name: 'Zebra ZQ520 del camión 12 — andén norte de Santa Cruz',
          ),
          _btZebra,
        ],
      );
      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();

      expect(find.byType(PrinterOptionCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testOnScreens('paso 2 WiFi con resultados y ayuda abierta', (
      tester,
      screen,
    ) async {
      final h = await _pump(tester, textScale: 1.3);
      await _enterWifi(tester);
      h.scanner.emit(
        _found(const [
          WifiPrinterHit(
            host: '192.168.100.254',
            port: 9100,
            name: 'Zebra Technologies ZTC ZD421-300dpi ZPL Andén Principal',
            isZebra: true,
          ),
          WifiPrinterHit(
            host: '192.168.2.154',
            port: 9100,
            name: 'RICOH IM 550 Oficina Administración Planta Alta',
          ),
          _unknownHit,
        ], done: false),
      );
      await tester.pump();
      await _scrollTo(tester, find.text('¿No aparece? Ingresar IP'));
      await tester.tap(find.text('¿No aparece? Ingresar IP'));
      await tester.pump();
      await _scrollTo(tester, find.text('Buscar en otra red'));
      await tester.tap(find.text('Buscar en otra red'));
      await tester.pump();

      expect(find.byType(WifiExtraNetworks), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testOnScreens('paso Listo con usuario y resultado', (tester, screen) async {
      final h = _Harness(detection: _officeNeedsUser);
      await _pump(tester, harness: h, textScale: 1.3);
      await _enterWifi(tester);
      h.scanner.emit(
        _found(const [
          WifiPrinterHit(
            host: '192.168.2.154',
            port: 9100,
            name: 'RICOH IM 550 Oficina Administración Planta Alta — Norte',
            isZebra: true,
          ),
        ]),
      );
      await tester.pump();
      await _scrollTo(tester, find.byType(PrinterOptionCard).first);
      await tester.tap(find.byType(PrinterOptionCard).first);
      await _settleShort(tester);

      expect(find.byType(PrinterCredentialsPrompt), findsOneWidget);
      // Con letra 1.3 y un nombre tan largo el aviso "Impresora guardada…"
      // ocupa media pantalla chica: se espera a que se vaya (2 s) antes de
      // tocar, como haría el operario. En frames cortos: el plazo del aviso
      // recién corre cuando terminó de entrar.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(SnackBar), findsNothing);
      await _scrollTo(tester, find.text('Guardar y probar'));
      await tester.tap(find.text('Guardar y probar'));
      await _settleShort(tester);
      expect(h.printer.prints, 1);
      expect(find.text('Terminar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });
  });
}
