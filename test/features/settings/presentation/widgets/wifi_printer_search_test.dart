import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/printing/extra_networks_notifier.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/scanned_network.dart';
import 'package:logistics_app/core/printing/wifi_printer_hit.dart';
import 'package:logistics_app/core/printing/wifi_printer_scanner.dart';
import 'package:logistics_app/core/printing/wifi_scan_progress.dart';
import 'package:logistics_app/features/settings/presentation/widgets/non_zebra_printer_dialog.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_option_card.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_printer_search.dart';

import '../../../../core/auth/test_fakes.dart';
import '../../../../support/button_finders.dart';
import '../../../../support/screen_sizes.dart';

// Búsqueda automática de impresoras WiFi: el escáner real se reemplaza por uno
// cuyo stream controla el test (nunca hay red). Las redes extra viven en un
// almacén seguro en memoria.

class _FakeScanner extends WifiPrinterScanner {
  StreamController<WifiScanProgress>? controller;
  int scans = 0;
  bool cancelled = false;

  @override
  Stream<WifiScanProgress> scan({int port = kDefaultWifiPort}) {
    scans++;
    cancelled = false;
    controller = StreamController<WifiScanProgress>(
      onCancel: () => cancelled = true,
    );
    return controller!.stream;
  }

  void emit(WifiScanProgress p) => controller!.add(p);
}

const _zebra = WifiPrinterHit(
  host: '192.168.1.40',
  port: 9100,
  name: 'Zebra ZD421',
  isZebra: true,
);
const _other = WifiPrinterHit(host: '192.168.1.77', port: 9100);
const _ricoh = WifiPrinterHit(
  host: '192.168.2.154',
  port: 9100,
  name: 'RICOH IM 550',
);

const _wifi = ScannedNetwork(label: '192.168.1.0/24');

WifiScanProgress _progress({
  int scanned = 100,
  List<WifiPrinterHit> found = const [],
  bool done = false,
  List<ScannedNetwork> networks = const [_wifi],
  bool discovering = false,
}) => WifiScanProgress(
  scanned: scanned,
  total: 253,
  found: found,
  networks: networks,
  done: done,
  discoveringServices: discovering,
);

Future<List<PrinterConfig>> _pump(
  WidgetTester tester,
  _FakeScanner scanner, {
  PrinterConfig? selected,
  double textScale = 1,
  FakeSecureStorage? storage,
}) async {
  final saved = <PrinterConfig>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wifiPrinterScannerProvider.overrideWithValue(scanner),
        secureStorageProvider.overrideWithValue(storage ?? FakeSecureStorage()),
      ],
      child: MaterialApp(
        home: withTextScale(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: WifiPrinterSearch(
                selected: selected,
                onSelect: (c) async => saved.add(c),
              ),
            ),
          ),
          scale: textScale,
        ),
      ),
    ),
  );
  await tester.pump();
  return saved;
}

Future<void> _startAndEmit(
  WidgetTester tester,
  _FakeScanner scanner,
  WifiScanProgress progress,
) async {
  await tester.tap(find.text('Buscar impresoras'));
  await tester.pump();
  scanner.emit(progress);
  await tester.pump();
}

void main() {
  testWidgets('antes de buscar: explica y ofrece "Buscar impresoras"', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);

    expect(find.textContaining('mismo WiFi'), findsOneWidget);
    expect(findButtonWithText<OutlinedButton>('Buscar impresoras'), findsOne);
    expect(scanner.scans, 0); // no busca solo
  });

  testWidgets('buscando: barra, avance y botón Detener', (tester) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);

    await tester.tap(find.text('Buscar impresoras'));
    await tester.pump();
    expect(scanner.scans, 1);
    expect(find.text('Detectando la red WiFi…'), findsOneWidget);

    scanner.emit(_progress(found: const [_zebra]));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.text('Buscando impresoras… 40% · 1 encontrada'),
      findsOneWidget,
    );
    expect(find.text('Zebra ZD421'), findsOneWidget); // en vivo
    expect(findButtonWithText<OutlinedButton>('Detener búsqueda'), findsOne);
  });

  testWidgets('buscando: porcentaje sin jerga y anunciadas solas', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);

    await _startAndEmit(
      tester,
      scanner,
      _progress(
        networks: const [
          ScannedNetwork(label: '10.168.50.0/23'),
          ScannedNetwork(label: '192.168.2.0/24', added: true),
        ],
        discovering: true,
      ),
    );

    expect(find.text('Buscando impresoras… 40%'), findsOneWidget);
    expect(find.text(WifiPrinterSearch.searchingAnnouncedText), findsOneWidget);
    expect(find.textContaining('Bonjour'), findsNothing);
  });

  testWidgets('red grande (/16): avisa que se busca solo su /22', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);

    await _startAndEmit(
      tester,
      scanner,
      _progress(
        networks: const [
          ScannedNetwork(label: '10.168.48.0/22', fullLabel: '10.168.0.0/16'),
        ],
      ),
    );

    expect(
      find.textContaining(
        'La red del teléfono (10.168.0.0/16) es muy grande: se busca en '
        '10.168.48.0/22',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Detener corta el barrido y conserva lo encontrado', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);
    await _startAndEmit(tester, scanner, _progress(found: const [_zebra]));

    await tester.tap(find.text('Detener búsqueda'));
    await tester.pump();

    expect(scanner.cancelled, isTrue);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Zebra ZD421'), findsOneWidget);
    expect(find.text('Buscar de nuevo'), findsOneWidget);
  });

  testWidgets('terminado: lista con Zebra marcada; tocar guarda la config', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    final saved = await _pump(tester, scanner);
    await _startAndEmit(
      tester,
      scanner,
      _progress(scanned: 253, found: const [_zebra, _other], done: true),
    );

    expect(find.text('Zebra ZD421'), findsOneWidget);
    expect(find.text('192.168.1.40:9100'), findsOneWidget);
    expect(find.text('Impresora de red'), findsOneWidget); // sin nombre
    expect(find.text('Zebra'), findsOneWidget); // pastilla solo en la Zebra
    expect(find.text('No es Zebra'), findsNothing);

    await tester.tap(find.text('Zebra ZD421'));
    await tester.pump();

    expect(find.byType(NonZebraPrinterDialog), findsNothing);
    expect(saved, hasLength(1));
    expect(saved.single.transport, PrinterTransport.wifi);
    expect(saved.single.address, '192.168.1.40:9100');
    expect(saved.single.label, 'Zebra ZD421');
  });

  testWidgets('sin identificar: "Modelo desconocido", sin pastillas', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    final saved = await _pump(tester, scanner);
    await _startAndEmit(
      tester,
      scanner,
      _progress(found: const [_other], done: true),
    );

    expect(find.text('192.168.1.77:9100 · Modelo desconocido'), findsOneWidget);
    expect(find.text('Zebra'), findsNothing);
    expect(find.text('No es Zebra'), findsNothing);

    // Sin nombre no se pide confirmación y se guarda como "WiFi <ip>".
    await tester.tap(find.text('Impresora de red'));
    await tester.pump();

    expect(find.byType(NonZebraPrinterDialog), findsNothing);
    expect(saved.single.label, 'WiFi 192.168.1.77');
  });

  group('impresora que no es Zebra', () {
    Future<List<PrinterConfig>> pumpRicoh(WidgetTester tester) async {
      final scanner = _FakeScanner();
      final saved = await _pump(tester, scanner);
      await _startAndEmit(
        tester,
        scanner,
        _progress(found: const [_zebra, _ricoh], done: true),
      );
      return saved;
    }

    testWidgets('pastilla de advertencia "No es Zebra"', (tester) async {
      await pumpRicoh(tester);

      expect(find.text('No es Zebra'), findsOneWidget);
      expect(find.text('Zebra'), findsOneWidget); // la de la ZD421
    });

    testWidgets('tocarla pide confirmación; Cancelar no guarda', (
      tester,
    ) async {
      final saved = await pumpRicoh(tester);

      await tester.tap(find.text('RICOH IM 550'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NonZebraPrinterDialog), findsOneWidget);
      expect(
        find.text(
          'RICOH IM 550 no parece una impresora de etiquetas Zebra. Si la '
          'elegís, las etiquetas pueden salir como texto. ¿Usarla igual?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NonZebraPrinterDialog), findsNothing);
      expect(saved, isEmpty);
    });

    testWidgets('"Usar igual" la guarda', (tester) async {
      final saved = await pumpRicoh(tester);

      await tester.tap(find.text('RICOH IM 550'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Usar igual'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(saved.single.address, '192.168.2.154:9100');
      expect(saved.single.label, 'RICOH IM 550');
    });
  });

  testWidgets('la activa aparece seleccionada', (tester) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner, selected: _zebra.toConfig());
    await _startAndEmit(
      tester,
      scanner,
      _progress(found: const [_zebra, _other], done: true),
    );

    final cards = tester
        .widgetList<PrinterOptionCard>(find.byType(PrinterOptionCard))
        .toList();
    expect(cards.where((c) => c.selected), hasLength(1));
  });

  testWidgets('sin resultados: red buscada y qué hacer', (tester) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);
    await _startAndEmit(tester, scanner, _progress(scanned: 253, done: true));

    final message = find.textContaining(
      'No se encontraron impresoras en la red 192.168.1.0/24.',
    );
    expect(message, findsOneWidget);
    final text = tester.widget<Text>(message).data!;
    expect(text, contains('encendida'));
    expect(text, contains('"¿No aparece? Ingresar IP"'));
    expect(text, isNot(contains('Bonjour')));

    await tester.tap(find.text('Buscar de nuevo'));
    await tester.pump();
    expect(scanner.scans, 2);
  });

  testWidgets('sin resultados en varias redes: las lista', (tester) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);
    await _startAndEmit(
      tester,
      scanner,
      _progress(
        done: true,
        networks: const [
          ScannedNetwork(label: '10.168.50.0/23'),
          ScannedNetwork(label: '192.168.2.0/24', added: true),
        ],
      ),
    );

    expect(
      find.textContaining(
        'No se encontraron impresoras en las redes 10.168.50.0/23, '
        '192.168.2.0/24.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin WiFi: muestra el aviso del escáner', (tester) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);
    await _startAndEmit(
      tester,
      scanner,
      const WifiScanProgress.failed(kNoLocalNetworkMessage),
    );

    expect(find.text(kNoLocalNetworkMessage), findsOneWidget);
    expect(find.text('Buscar de nuevo'), findsOneWidget);
  });

  testWidgets('error del stream: aviso genérico, sin colgarse', (tester) async {
    final scanner = _FakeScanner();
    await _pump(tester, scanner);
    await tester.tap(find.text('Buscar impresoras'));
    await tester.pump();
    scanner.controller!.addError(StateError('boom'));
    await tester.pump();

    expect(find.textContaining('No se pudo buscar impresoras'), findsOneWidget);
  });

  testOnScreens('resultados en vivo no desbordan con letra grande', (
    tester,
    screen,
  ) async {
    final storage = FakeSecureStorage()
      ..seed(
        ExtraNetworksNotifier.storageKey,
        '["192.168.2.0/24","10.20.0.0/22","172.16.100.0/24"]',
      );
    final scanner = _FakeScanner();
    await _pump(tester, scanner, textScale: 1.3, storage: storage);
    await tester.tap(find.text('Buscar impresoras'));
    await tester.pump();
    scanner.emit(
      _progress(
        networks: const [
          ScannedNetwork(label: '10.168.48.0/22', fullLabel: '10.168.0.0/16'),
          ScannedNetwork(label: '192.168.2.0/24', added: true),
        ],
        discovering: true,
        found: const [
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
          _other,
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(PrinterOptionCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
