import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_printer_form.dart';

// Formulario de impresora WiFi: IP (obligatoria) y puerto (default 9100).

Future<PrinterConfig?> _pumpAndSave(
  WidgetTester tester, {
  String? ip,
  String? port,
  PrinterConfig? initial,
}) async {
  PrinterConfig? saved;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WifiPrinterForm(
          initial: initial,
          onSave: (config) async => saved = config,
        ),
      ),
    ),
  );
  if (ip != null) {
    await tester.enterText(
      find.widgetWithText(TextField, 'IP de la impresora'),
      ip,
    );
  }
  if (port != null) {
    await tester.enterText(find.widgetWithText(TextField, 'Puerto'), port);
  }
  await tester.tap(find.text('Guardar impresora WiFi'));
  await tester.pump();
  return saved;
}

void main() {
  testWidgets('IP vacía: muestra aviso y no guarda', (tester) async {
    final saved = await _pumpAndSave(tester, ip: '');

    expect(find.text('Ingresá la IP de la impresora.'), findsOneWidget);
    expect(saved, isNull);
  });

  testWidgets('IP válida con puerto por defecto: guarda ip:9100', (
    tester,
  ) async {
    final saved = await _pumpAndSave(tester, ip: '192.168.1.50');

    expect(saved, isNotNull);
    expect(saved!.transport, PrinterTransport.wifi);
    expect(saved.address, '192.168.1.50:9100');
    expect(saved.label, 'WiFi 192.168.1.50');
    expect(saved.wifiHost, '192.168.1.50');
    expect(saved.wifiPort, 9100);
  });

  testWidgets('puerto personalizado: se respeta', (tester) async {
    final saved = await _pumpAndSave(tester, ip: '10.0.0.5', port: '9200');

    expect(saved!.address, '10.0.0.5:9200');
    expect(saved.wifiPort, 9200);
  });

  testWidgets('puerto no numérico: cae a 9100', (tester) async {
    final saved = await _pumpAndSave(tester, ip: '10.0.0.5', port: 'abc');

    expect(saved!.address, '10.0.0.5:9100');
  });

  testWidgets('precarga la IP cuando la impresora inicial es WiFi', (
    tester,
  ) async {
    const initial = PrinterConfig(
      transport: PrinterTransport.wifi,
      address: '172.16.0.9:9100',
      label: 'WiFi 172.16.0.9',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WifiPrinterForm(initial: initial, onSave: (_) async {}),
        ),
      ),
    );

    expect(find.text('172.16.0.9'), findsOneWidget);
  });
}
