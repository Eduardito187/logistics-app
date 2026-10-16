import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_controllers.dart';
import 'package:logistics_app/features/settings/presentation/widgets/discovered_printers.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_section.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_printer_form.dart';
import '../../../../support/button_finders.dart';

// Sección de impresora: elige transporte, descubre/ingresa, guarda e imprime
// prueba. Se override la impresora seleccionada y el descubrimiento; el core de
// impresión es un falso.

class _FakeLabelPrinter implements LabelPrinter {
  @override
  Future<List<PrinterDevice>> discover(PrinterTransport transport) async =>
      const [];
  @override
  Future<PrinterConfig?> selectedPrinter() async => null;
  @override
  Future<void> selectPrinter(PrinterConfig config) async {}
  @override
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {}
}

Future<void> _pump(
  WidgetTester tester, {
  PrinterConfig? selected,
  bool printing = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        labelPrinterProvider.overrideWithValue(_FakeLabelPrinter()),
        selectedPrinterProvider.overrideWith((ref) async => selected),
        discoveredPrintersProvider(
          PrinterTransport.bluetooth,
        ).overrideWith((ref) async => const []),
        discoveredPrintersProvider(
          PrinterTransport.usb,
        ).overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PrinterSection(printing: printing, onPrintTest: () async {}),
        ),
      ),
    ),
  );
  if (printing) {
    // El spinner anima sin fin: pumpAndSettle nunca terminaría. Unos frames
    // alcanzan para resolver los providers async.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('muestra los tres transportes y el botón de prueba', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Bluetooth'), findsOneWidget);
    expect(find.text('WiFi'), findsOneWidget);
    expect(find.text('USB'), findsOneWidget);
    expect(find.text('Imprimir prueba'), findsOneWidget);
  });

  testWidgets('por defecto (Bluetooth) muestra el descubrimiento, no el form', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(DiscoveredPrinters), findsOneWidget);
    expect(find.byType(WifiPrinterForm), findsNothing);
  });

  testWidgets('al elegir WiFi muestra el formulario manual', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('WiFi'));
    await tester.pumpAndSettle();

    expect(find.byType(WifiPrinterForm), findsOneWidget);
    expect(find.byType(DiscoveredPrinters), findsNothing);
  });

  testWidgets('con impresora activa muestra la pastilla', (tester) async {
    await _pump(
      tester,
      selected: const PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.1.50:9100',
        label: 'WiFi 192.168.1.50',
      ),
    );

    expect(find.textContaining('Activa: WiFi 192.168.1.50'), findsOneWidget);
  });

  testWidgets('printing=true: el botón de prueba muestra spinner', (
    tester,
  ) async {
    await _pump(tester, printing: true);

    expect(
      find.descendant(
        of: findButtonWithText<OutlinedButton>('Imprimir prueba'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });
}
