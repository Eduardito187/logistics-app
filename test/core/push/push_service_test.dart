import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/push/push_service.dart';

// messageFrom/payloadOf: la parte de PushService libre de plataforma. Normaliza
// un RemoteMessage de FCM al PushMessage que se muestra y al payload del tap.
// El backend publica `notification` {title, body} + `data` {notification_id,
// shipment_id, message_type}.

void main() {
  final service = PushService();

  group('messageFrom', () {
    test('usa el bloque notification de FCM', () {
      final msg = service.messageFrom(
        const RemoteMessage(
          notification: RemoteNotification(title: 'Ruta lista', body: 'Sal ya'),
          data: {'notification_id': 'N-1', 'shipment_id': 'SHP-7'},
        ),
      );
      expect(msg.title, 'Ruta lista');
      expect(msg.body, 'Sal ya');
      expect(msg.payload, 'N-1');
    });

    test('mensaje solo-data: toma title y body de data', () {
      final msg = service.messageFrom(
        const RemoteMessage(data: {'title': 'Andén 3', 'body': 'Carga lista'}),
      );
      expect(msg.title, 'Andén 3');
      expect(msg.body, 'Carga lista');
    });

    test('acepta "message" como cuerpo en data', () {
      final msg = service.messageFrom(
        const RemoteMessage(data: {'message': 'Texto'}),
      );
      expect(msg.body, 'Texto');
    });

    test('sin contenido cae a título y cuerpo genéricos', () {
      final msg = service.messageFrom(const RemoteMessage());
      expect(msg.title, 'Operación');
      expect(msg.body, 'Tienes una novedad en la operación.');
      expect(msg.payload, isNull);
    });

    test('título vacío en notification usa el de data', () {
      final msg = service.messageFrom(
        const RemoteMessage(
          notification: RemoteNotification(title: '', body: 'b'),
          data: {'title': 'Desde data'},
        ),
      );
      expect(msg.title, 'Desde data');
    });
  });

  group('payloadOf', () {
    test('prioridad: notification_id > shipment_id > tag > id', () {
      expect(
        service.payloadOf(
          const RemoteMessage(
            data: {'shipment_id': 'S', 'notification_id': 'N', 'id': 'I'},
          ),
        ),
        'N',
      );
      expect(
        service.payloadOf(
          const RemoteMessage(data: {'shipment_id': 'S', 'tag': 'T'}),
        ),
        'S',
      );
      expect(
        service.payloadOf(const RemoteMessage(data: {'tag': 'T', 'id': 'I'})),
        'T',
      );
      expect(service.payloadOf(const RemoteMessage(data: {'id': 'I'})), 'I');
    });

    test('ignora valores vacíos', () {
      expect(
        service.payloadOf(
          const RemoteMessage(data: {'notification_id': '', 'id': 'I'}),
        ),
        'I',
      );
    });
  });
}
