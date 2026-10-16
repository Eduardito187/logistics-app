import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_controllers.dart';
import 'package:logistics_app/features/settings/presentation/widgets/discovered_printers.dart';

// Lista de impresoras descubiertas (Bluetooth/USB). Elegir una la guarda. Se
// override el provider de descubrimiento con datos/vacío/error.

const _zebra = PrinterDevice(
  transport: PrinterTransport.bluetooth,
  address: 'AA:BB:CC',
  name: 'Zebra ZQ630',
);

Future<PrinterConfig?> _pump(
  WidgetTester tester, {
  required PrinterTransport transport,
  required Future<List<PrinterDevice>> Function() load,
}) async {
  PrinterConfig? selected;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveredPrintersProvider(transport).overrideWith((ref) => load()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DiscoveredPrinters(
            transport: transport,
            selected: null,
            onSelect: (config) async => selected = config,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return selected;
}

void main() {
  testWidgets('Bluetooth sin impresoras: muestra el mensaje de emparejar', (
    tester,
  ) async {
    await _pump(
      tester,
      transport: PrinterTransport.bluetooth,
      load: () async => const [],
    );

    expect(
      find.textContaining('No hay impresoras emparejadas'),
      findsOneWidget,
    );
  });

  testWidgets('USB sin impresoras: muestra el mensaje de conectar por cable', (
    tester,
  ) async {
    await _pump(
      tester,
      transport: PrinterTransport.usb,
      load: () async => const [],
    );

    expect(
      find.textContaining('No hay impresoras USB conectadas'),
      findsOneWidget,
    );
  });

  testWidgets('con impresoras: lista nombre y dirección', (tester) async {
    await _pump(
      tester,
      transport: PrinterTransport.bluetooth,
      load: () async => const [_zebra],
    );

    expect(find.text('Zebra ZQ630'), findsOneWidget);
    expect(find.text('AA:BB:CC'), findsOneWidget);
  });

  testWidgets('elegir una impresora llama onSelect con su config', (
    tester,
  ) async {
    PrinterConfig? captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveredPrintersProvider(PrinterTransport.bluetooth)
              .overrideWith((ref) async => const [_zebra]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DiscoveredPrinters(
              transport: PrinterTransport.bluetooth,
              selected: null,
              onSelect: (config) async => captured = config,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zebra ZQ630'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.address, 'AA:BB:CC');
    expect(captured!.transport, PrinterTransport.bluetooth);
  });

  testWidgets('error al descubrir: muestra el estado de error', (tester) async {
    await _pump(
      tester,
      transport: PrinterTransport.bluetooth,
      load: () async => throw const ApiException(status: 0, title: 'Falló'),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
