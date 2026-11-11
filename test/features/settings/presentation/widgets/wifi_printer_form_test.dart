import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/core/printing/ipv4.dart';
import 'package:logistics_app/core/printing/ipv4_subnet.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/printer_reachability.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_save_result.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_printer_form.dart';

import '../../../../support/app_icon_finders.dart';
import '../../../../support/button_finders.dart';

// Formulario de impresora WiFi: IP (obligatoria), puerto (default 9100),
// "Probar conexión" con diagnóstico y guardado con estado visible.

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
          onSave: (config) async {
            saved = config;
            return PrinterSaveResult.saved;
          },
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
  // Deja vencer el ícono de resultado (timer de 2 s).
  await tester.pump(WifiPrinterForm.saveFeedback);
  return saved;
}

Ipv4Subnet _net(String ip, int prefix) =>
    Ipv4Subnet.containing(Ipv4.parse(ip)!, prefix);

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

  testWidgets('IP con formato inválido: avisa y no guarda', (tester) async {
    final saved = await _pumpAndSave(tester, ip: '192.168.1.300');

    expect(find.text('IP inválida. Ej. 192.168.1.50'), findsOneWidget);
    expect(saved, isNull);
  });

  testWidgets('puerto fuera de rango: cae a 9100', (tester) async {
    final saved = await _pumpAndSave(tester, ip: '10.0.0.5', port: '70000');

    expect(saved!.address, '10.0.0.5:9100');
  });

  test('isValidIpv4', () {
    expect(WifiPrinterForm.isValidIpv4('192.168.1.50'), isTrue);
    expect(WifiPrinterForm.isValidIpv4('0.0.0.0'), isTrue);
    expect(WifiPrinterForm.isValidIpv4('256.1.1.1'), isFalse);
    expect(WifiPrinterForm.isValidIpv4('1.2.3'), isFalse);
    expect(WifiPrinterForm.isValidIpv4('1..2.3'), isFalse);
    expect(WifiPrinterForm.isValidIpv4('1.2.3.4.5'), isFalse);
  });

  group('Guardar: estado visible', () {
    Future<Completer<PrinterSaveResult>> pumpPending(
      WidgetTester tester,
    ) async {
      final pending = Completer<PrinterSaveResult>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiPrinterForm(
              initial: null,
              onSave: (_) => pending.future,
            ),
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'IP de la impresora'),
        '192.168.1.50',
      );
      await tester.tap(find.text('Guardar impresora WiFi'));
      await tester.pump();
      return pending;
    }

    testWidgets('mientras guarda: "Guardando…", deshabilitado y cargando', (
      tester,
    ) async {
      final pending = await pumpPending(tester);

      expect(find.text('Guardando…'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Guardando…'),
      );
      expect(button.onPressed, isNull);
      expect(
        findAppIconInState(AppIcon.save, AppIconState.loading),
        findsOneWidget,
      );

      pending.complete(PrinterSaveResult.saved);
      await tester.pump();
      await tester.pump();

      expect(find.text('Guardar impresora WiFi'), findsOneWidget);
      expect(
        findAppIconInState(AppIcon.save, AppIconState.success),
        findsOneWidget,
      );

      // El check es breve: vuelve a reposo.
      await tester.pump(WifiPrinterForm.saveFeedback);
      expect(
        findAppIconInState(AppIcon.save, AppIconState.idle),
        findsOneWidget,
      );
    });

    testWidgets('ya era la activa: también termina en check', (tester) async {
      final pending = await pumpPending(tester);

      pending.complete(PrinterSaveResult.unchanged);
      await tester.pump();
      await tester.pump();

      expect(
        findAppIconInState(AppIcon.save, AppIconState.success),
        findsOneWidget,
      );
      await tester.pump(WifiPrinterForm.saveFeedback);
    });

    testWidgets('falla: ícono de error y botón habilitado otra vez', (
      tester,
    ) async {
      final pending = await pumpPending(tester);

      pending.complete(PrinterSaveResult.failed);
      await tester.pump();
      await tester.pump();

      expect(
        findAppIconInState(AppIcon.save, AppIconState.error),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Guardar impresora WiFi'),
      );
      expect(button.onPressed, isNotNull);
      await tester.pump(WifiPrinterForm.saveFeedback);
    });
  });

  group('Probar conexión', () {
    Future<List<(String, int)>> pumpWithTest(
      WidgetTester tester, {
      required PrinterReachability result,
      String ip = '192.168.1.50',
      String? port,
      List<Ipv4Subnet>? phoneNetworks,
    }) async {
      final calls = <(String, int)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WifiPrinterForm(
                initial: null,
                onSave: (_) async => PrinterSaveResult.saved,
                onTest: (host, port) async {
                  calls.add((host, port));
                  return result;
                },
                phoneNetworks: phoneNetworks == null
                    ? null
                    : () async => phoneNetworks,
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'IP de la impresora'),
        ip,
      );
      if (port != null) {
        await tester.enterText(find.widgetWithText(TextField, 'Puerto'), port);
      }
      await tester.tap(find.text('Probar conexión'));
      await tester.pump();
      await tester.pump();
      return calls;
    }

    testWidgets('sin onTest no aparece el botón', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiPrinterForm(
              initial: null,
              onSave: (_) async => PrinterSaveResult.saved,
            ),
          ),
        ),
      );
      expect(find.text('Probar conexión'), findsNothing);
    });

    testWidgets('responde: lo dice con ip:puerto', (tester) async {
      final calls = await pumpWithTest(
        tester,
        result: PrinterReachability.reachable,
      );

      expect(calls, [('192.168.1.50', 9100)]);
      expect(
        find.text('La impresora responde en 192.168.1.50:9100.'),
        findsOneWidget,
      );
      expect(
        findAppIconInState(AppIcon.wifi, AppIconState.success),
        findsOneWidget,
      );
    });

    testWidgets('rechazado: hay equipo pero no acepta el puerto', (
      tester,
    ) async {
      await pumpWithTest(
        tester,
        result: PrinterReachability.refused,
        port: '9101',
      );

      expect(
        find.text(
          'Hay un equipo en esa IP pero no acepta impresión en el puerto '
          '9101. Revisá el puerto (Zebra: 9100).',
        ),
        findsOneWidget,
      );
      expect(
        findAppIconInState(AppIcon.wifi, AppIconState.error),
        findsOneWidget,
      );
    });

    testWidgets('timeout: no hay conexión desde el WiFi', (tester) async {
      await pumpWithTest(tester, result: PrinterReachability.timeout);

      expect(
        find.textContaining(
          'No hay conexión desde el WiFi de este teléfono hasta '
          '192.168.1.50.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('pedí a sistemas'), findsOneWidget);
    });

    testWidgets('sin ruta y IP de otra red: nota antes del diagnóstico', (
      tester,
    ) async {
      await pumpWithTest(
        tester,
        result: PrinterReachability.noRoute,
        ip: '192.168.2.154',
        phoneNetworks: [
          _net('10.168.50.17', 23),
          _net('172.30.220.5', 20),
        ],
      );

      expect(
        find.textContaining(
          'Esa IP es de otra red distinta a la del teléfono '
          '(10.168.50.0/23, 172.30.208.0/20). No hay conexión desde el WiFi',
        ),
        findsOneWidget,
      );
    });

    testWidgets('IP de la misma red: sin la nota de otra red', (tester) async {
      await pumpWithTest(
        tester,
        result: PrinterReachability.timeout,
        phoneNetworks: [_net('192.168.1.20', 24)],
      );

      expect(find.textContaining('otra red distinta'), findsNothing);
    });

    testWidgets('cambiar la IP borra el resultado anterior', (tester) async {
      await pumpWithTest(tester, result: PrinterReachability.timeout);
      expect(find.textContaining('No hay conexión'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'IP de la impresora'),
        '192.168.1.51',
      );
      await tester.pump();

      expect(find.textContaining('No hay conexión'), findsNothing);
    });

    testWidgets('IP inválida: no prueba', (tester) async {
      final calls = await pumpWithTest(
        tester,
        result: PrinterReachability.reachable,
        ip: '999.1.1.1',
      );

      expect(calls, isEmpty);
      expect(find.text('IP inválida. Ej. 192.168.1.50'), findsOneWidget);
    });
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
          body: WifiPrinterForm(
            initial: initial,
            onSave: (_) async => PrinterSaveResult.saved,
          ),
        ),
      ),
    );

    expect(find.text('172.16.0.9'), findsOneWidget);
  });
}
