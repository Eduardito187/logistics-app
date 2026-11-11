import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/print_outcome.dart';
import 'package:logistics_app/core/printing/printer_credentials.dart';
import 'package:logistics_app/core/printing/printer_credentials_store.dart';
import 'package:logistics_app/core/printing/printer_exception.dart';

import '../auth/test_fakes.dart';

// Credenciales por impresora (almacén seguro, nunca en logs) y textos veraces
// del resultado de impresión.

void main() {
  group('PrinterCredentials', () {
    const full = PrinterCredentials(
      username: 'jperez',
      password: 'Secreto#1',
      userCode: '4321',
      domain: 'DISMAC',
    );

    test('usuario de autenticación con dominio', () {
      expect(full.authUser, r'DISMAC\jperez');
      expect(
        const PrinterCredentials(username: ' ana ').authUser,
        'ana',
      );
    });

    test('toString nunca muestra la contraseña ni el código', () {
      final text = full.toString();
      expect(text, isNot(contains('Secreto#1')));
      expect(text, isNot(contains('4321')));
      expect(text, contains('***'));
    });

    test('JSON ida y vuelta; vacíos se omiten', () {
      expect(PrinterCredentials.decode(full.encode()), full);
      final minimal = const PrinterCredentials(username: 'ana').toJson();
      expect(minimal, {'username': 'ana'});
      expect(PrinterCredentials.decode('{roto'), isNull);
      expect(PrinterCredentials.decode('{"x":1}'), isNull);
    });
  });

  group('PrinterCredentialsStore', () {
    test('guarda y lee por dirección de impresora', () async {
      final storage = FakeSecureStorage();
      final store = PrinterCredentialsStore(storage);
      const creds = PrinterCredentials(username: 'jperez', password: 'pw');

      await store.write('192.168.2.154:9100', creds);

      expect(await store.read('192.168.2.154:9100'), creds);
      expect(await store.read('192.168.2.155:9100'), isNull);
      expect(
        storage.data.keys,
        ['printer_credentials_192.168.2.154:9100'],
      );
    });

    test('usuario vacío o null borra', () async {
      final storage = FakeSecureStorage();
      final store = PrinterCredentialsStore(storage);
      await store.write('h:9100', const PrinterCredentials(username: 'a'));

      await store.write('h:9100', const PrinterCredentials(username: '  '));
      expect(await store.read('h:9100'), isNull);

      await store.write('h:9100', const PrinterCredentials(username: 'b'));
      await store.write('h:9100', null);
      expect(storage.data, isEmpty);
    });
  });

  group('PrintOutcome — textos veraces', () {
    test('IPP recibido (sin estado final), con y sin número', () {
      expect(
        const PrintOutcome.accepted(jobId: 123).message,
        'La impresora recibió el trabajo (#123) pero no confirmó si lo imprimió. '
        'Revisá que haya salido.',
      );
      expect(
        const PrintOutcome.accepted().message,
        'La impresora recibió el trabajo pero no confirmó si lo imprimió. '
        'Revisá que haya salido.',
      );
      expect(
        const PrintOutcome.accepted(
          jobId: 5,
          note: 'La impresora está sin papel.',
        ).message,
        'La impresora recibió el trabajo (#5) pero no confirmó si lo imprimió. '
        'Revisá que haya salido. '
        'La impresora está sin papel.',
      );
    });

    test('IPP impreso y retenido', () {
      expect(
        const PrintOutcome.printed(jobId: 9).message,
        'Impreso: la impresora confirmó el trabajo (#9).',
      );
      expect(
        const PrintOutcome.held(jobId: 9).message,
        'La impresora retuvo el trabajo (#9): liberalo desde el panel de la '
        'impresora con tu usuario.',
      );
      expect(const PrintOutcome.printed().confirmed, isTrue);
      expect(const PrintOutcome.held().confirmed, isTrue);
    });

    test('9100 sin confirmación lo dice', () {
      const outcome = PrintOutcome.sentUnconfirmed();
      expect(
        outcome.message,
        'Enviado. Esta impresora no confirma la impresión; revisá que haya '
        'salido.',
      );
      expect(outcome.confirmed, isFalse);
      expect(const PrintOutcome.ready().confirmed, isTrue);
    });

    test('sin impresora → pide configurarla', () {
      expect(PrinterException.notSelected.needsSetup, isTrue);
      expect(
        PrinterException.notSelected.message,
        'No hay impresora seleccionada.',
      );
    });
  });
}
