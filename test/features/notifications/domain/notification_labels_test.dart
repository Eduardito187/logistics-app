import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/channel.dart';
import 'package:logistics_app/core/api/models/message_type.dart';
import 'package:logistics_app/core/api/models/notification_status.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';
import 'package:logistics_app/features/notifications/domain/notification_labels.dart';

// Traducciones al español y tonos de los enums de notificación. Son el texto
// que ve el usuario: si el backend agrega un valor, el switch obliga a mapearlo.

void main() {
  group('MessageTypeLabel', () {
    test('traduce cada tipo de mensaje', () {
      expect(MessageType.enRoute.label, 'En ruta');
      expect(MessageType.arriving.label, 'Por llegar');
      expect(MessageType.delivered.label, 'Entregado');
      expect(MessageType.failed.label, 'Entrega fallida');
      expect(MessageType.confirmLocation.label, 'Confirmar ubicación');
      expect(MessageType.$unknown.label, 'Otro');
    });
  });

  group('NotificationStatusLabel', () {
    test('traduce cada estado', () {
      expect(NotificationStatus.queued.label, 'En cola');
      expect(NotificationStatus.sent.label, 'Enviada');
      expect(NotificationStatus.failed.label, 'Fallida');
      expect(NotificationStatus.suppressed.label, 'Suprimida');
      expect(NotificationStatus.$unknown.label, 'Desconocido');
    });

    test('asigna el tono semántico', () {
      expect(NotificationStatus.queued.tone, PillTone.info);
      expect(NotificationStatus.sent.tone, PillTone.success);
      expect(NotificationStatus.failed.tone, PillTone.danger);
      expect(NotificationStatus.suppressed.tone, PillTone.neutral);
    });

    test('solo una notificación en cola se puede suprimir', () {
      expect(NotificationStatus.queued.canSuppress, isTrue);
      expect(NotificationStatus.sent.canSuppress, isFalse);
      expect(NotificationStatus.failed.canSuppress, isFalse);
    });
  });

  group('ChannelLabel', () {
    test('traduce cada canal', () {
      expect(Channel.fcm.label, 'Push (Firebase)');
      expect(Channel.telegram.label, 'Telegram');
      expect(Channel.email.label, 'Correo');
      expect(Channel.sms.label, 'SMS');
      expect(Channel.$unknown.label, 'Otro');
    });
  });
}
