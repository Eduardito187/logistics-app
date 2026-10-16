import '../../../core/api/models/channel.dart';
import '../../../core/api/models/message_type.dart';
import '../../../core/api/models/notification_status.dart';
import '../../../core/widgets/status_pill.dart';

/// Traducciones y tonos de color para los enums de notificación. El backend
/// manda códigos (EN_ROUTE, QUEUED...); acá se muestran en español.
extension MessageTypeLabel on MessageType {
  String get label => switch (this) {
    MessageType.enRoute => 'En ruta',
    MessageType.arriving => 'Por llegar',
    MessageType.delivered => 'Entregado',
    MessageType.failed => 'Entrega fallida',
    MessageType.confirmLocation => 'Confirmar ubicación',
    MessageType.$unknown => 'Otro',
  };
}

extension NotificationStatusLabel on NotificationStatus {
  String get label => switch (this) {
    NotificationStatus.queued => 'En cola',
    NotificationStatus.sent => 'Enviada',
    NotificationStatus.failed => 'Fallida',
    NotificationStatus.suppressed => 'Suprimida',
    NotificationStatus.$unknown => 'Desconocido',
  };

  PillTone get tone => switch (this) {
    NotificationStatus.queued => PillTone.info,
    NotificationStatus.sent => PillTone.success,
    NotificationStatus.failed => PillTone.danger,
    NotificationStatus.suppressed => PillTone.neutral,
    NotificationStatus.$unknown => PillTone.neutral,
  };

  bool get canSuppress => this == NotificationStatus.queued;
}

extension ChannelLabel on Channel {
  String get label => switch (this) {
    Channel.pushNtfy => 'Push (ntfy)',
    Channel.webPush => 'Web push',
    Channel.telegram => 'Telegram',
    Channel.email => 'Correo',
    Channel.sms => 'SMS',
    Channel.$unknown => 'Otro',
  };
}
