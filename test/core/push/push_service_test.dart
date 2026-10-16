import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/push/push_service.dart';

// Solo se prueba decodeMessage: es la única pieza de PushService libre de
// plataforma (utf8 + json). El resto (initialize, register, showMessage,
// permisos) habla con UnifiedPush / flutter_local_notifications vía
// MethodChannel y necesita pruebas de integración.

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  final service = PushService();

  group('decodeMessage', () {
    test('JSON de ntfy con title, message y tag', () {
      final msg = service.decodeMessage(
        _bytes('{"title":"Ruta lista","message":"Sal ya","tag":"SHP-7"}'),
      );
      expect(msg.title, 'Ruta lista');
      expect(msg.body, 'Sal ya');
      expect(msg.payload, 'SHP-7');
    });

    test('usa "id" como payload cuando no hay "tag"', () {
      final msg = service.decodeMessage(
        _bytes('{"title":"t","message":"b","id":"N-99"}'),
      );
      expect(msg.payload, 'N-99');
    });

    test('"tag" tiene prioridad sobre "id"', () {
      final msg = service.decodeMessage(
        _bytes('{"message":"b","tag":"T","id":"I"}'),
      );
      expect(msg.payload, 'T');
    });

    test('tag vacío deja payload en null', () {
      final msg = service.decodeMessage(_bytes('{"message":"b","tag":""}'));
      expect(msg.payload, isNull);
    });

    test('sin title usa el título genérico "Operación"', () {
      final msg = service.decodeMessage(_bytes('{"message":"solo cuerpo"}'));
      expect(msg.title, 'Operación');
      expect(msg.body, 'solo cuerpo');
    });

    test('title vacío cae al genérico', () {
      final msg = service.decodeMessage(_bytes('{"title":"","message":"x"}'));
      expect(msg.title, 'Operación');
    });

    test('message ausente o vacío: el cuerpo es el texto crudo', () {
      final raw = '{"title":"t"}';
      final msg = service.decodeMessage(_bytes(raw));
      expect(msg.title, 't');
      expect(msg.body, raw);
    });

    test('texto plano (no JSON): título genérico y cuerpo = texto', () {
      final msg = service.decodeMessage(_bytes('Tenés una entrega nueva'));
      expect(msg.title, 'Operación');
      expect(msg.body, 'Tenés una entrega nueva');
      expect(msg.payload, isNull);
    });

    test('JSON que no es objeto (una lista) cae a texto crudo', () {
      final raw = '[1,2,3]';
      final msg = service.decodeMessage(_bytes(raw));
      expect(msg.title, 'Operación');
      expect(msg.body, raw);
    });

    test('bytes UTF-8 inválidos: aviso genérico sin lanzar', () {
      final msg = service.decodeMessage(Uint8List.fromList([0xC3, 0x28]));
      expect(msg.title, 'Operación');
      expect(msg.body, 'Tienes una novedad en la operación.');
      expect(msg.payload, isNull);
    });
  });
}
