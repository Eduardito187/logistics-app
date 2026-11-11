import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/printer_credentials.dart';
import 'package:logistics_app/core/printing/printer_credentials_store.dart';
import 'package:logistics_app/features/settings/presentation/controllers/printer_save_result.dart';
import 'package:logistics_app/features/settings/presentation/widgets/printer_access_section.dart';

import '../../../../core/auth/test_fakes.dart';

// "Acceso a la impresora": tipo (Zebra/oficina), protocolo y credenciales por
// impresora en el almacén seguro (el teléfono no puede leer el usuario del
// WiFi ni del dominio).

const _office = PrinterConfig(
  transport: PrinterTransport.wifi,
  address: '192.168.2.154:9100',
  label: 'RICOH IM 550',
  language: PrinterLanguage.office,
  protocol: PrinterProtocol.ipp,
);

class _Harness {
  final storage = FakeSecureStorage();
  final saved = <PrinterConfig>[];
}

Future<_Harness> _pump(
  WidgetTester tester, {
  PrinterConfig printer = _office,
  String? defaultUser = 'jperez',
  _Harness? harness,
}) async {
  final h = harness ?? _Harness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [secureStorageProvider.overrideWithValue(h.storage)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrinterAccessSection(
              printer: printer,
              defaultUser: defaultUser,
              onSaveConfig: (config) async {
                h.saved.add(config);
                return PrinterSaveResult.saved;
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

Finder _field(String label) => find.widgetWithText(TextField, label);

String _text(WidgetTester tester, String label) =>
    tester.widget<TextField>(_field(label)).controller!.text;

void main() {
  testWidgets('prellena el usuario con el de la sesión', (tester) async {
    await _pump(tester);

    expect(_text(tester, 'Usuario'), 'jperez');
    expect(find.text(PrinterAccessSection.helpText), findsOneWidget);
  });

  testWidgets('las credenciales guardadas ganan al usuario de la sesión', (
    tester,
  ) async {
    final h = _Harness();
    await PrinterCredentialsStore(h.storage).write(
      _office.address,
      const PrinterCredentials(
        username: 'ana',
        domain: 'DISMAC',
        userCode: '1234',
      ),
    );
    await _pump(tester, harness: h);

    expect(_text(tester, 'Usuario'), 'ana');
    expect(_text(tester, 'Dominio (opcional)'), 'DISMAC');
    expect(_text(tester, 'Código de usuario (opcional, Ricoh)'), '1234');
  });

  testWidgets('guardar acceso escribe en el almacén seguro por impresora', (
    tester,
  ) async {
    final h = await _pump(tester);

    await tester.enterText(_field('Dominio (opcional)'), 'DISMAC');
    await tester.enterText(_field('Contraseña (opcional)'), 's3cr3t');
    await tester.enterText(
      _field('Código de usuario (opcional, Ricoh)'),
      '777',
    );
    await tester.ensureVisible(find.text('Guardar acceso'));
    await tester.tap(find.text('Guardar acceso'));
    await tester.pump();
    await tester.pump();

    final stored = await PrinterCredentialsStore(
      h.storage,
    ).read(_office.address);
    expect(
      stored,
      const PrinterCredentials(
        username: 'jperez',
        domain: 'DISMAC',
        password: 's3cr3t',
        userCode: '777',
      ),
    );
    expect(stored!.authUser, r'DISMAC\jperez');
    expect(find.text('Acceso a la impresora guardado.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('la contraseña va oculta y se puede mostrar', (tester) async {
    await _pump(tester);

    TextField password() =>
        tester.widget<TextField>(_field('Contraseña (opcional)'));
    expect(password().obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();
    expect(password().obscureText, isFalse);

    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pumpAndSettle();
    expect(password().obscureText, isTrue);
  });

  testWidgets('ya no duplica el botón de prueba (está en la tarjeta)', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Probar impresión'), findsNothing);
    expect(find.text('Guardar acceso'), findsOneWidget);
  });

  testWidgets('Zebra: sin campos de credenciales; elegir oficina → IPP', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      printer: const PrinterConfig(
        transport: PrinterTransport.wifi,
        address: '192.168.1.9:9100',
        label: 'Zebra ZD421',
      ),
    );

    expect(_field('Usuario'), findsNothing);
    await tester.tap(find.text('Impresora de oficina (PDF)'));
    await tester.pumpAndSettle();

    expect(h.saved.single.language, PrinterLanguage.office);
    expect(h.saved.single.protocol, PrinterProtocol.ipp);
  });

  testWidgets('oficina por 9100: avisa que solo sirve el código de usuario', (
    tester,
  ) async {
    await _pump(
      tester,
      printer: _office.copyWith(protocol: PrinterProtocol.raw9100),
    );

    expect(find.text(PrinterAccessSection.rawHelpText), findsOneWidget);
  });

  testWidgets('cambiar a envío directo (9100) guarda el protocolo', (
    tester,
  ) async {
    final h = await _pump(tester);
    const direct = 'Envío directo (puerto 9100): no confirma';

    await tester.ensureVisible(find.text(direct));
    await tester.tap(find.text(direct));
    await tester.pumpAndSettle();

    expect(h.saved.single.protocol, PrinterProtocol.raw9100);
    expect(h.saved.single.language, PrinterLanguage.office);
  });
}
