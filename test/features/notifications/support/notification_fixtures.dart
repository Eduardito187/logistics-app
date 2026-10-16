import 'package:logistics_app/core/api/models/channel.dart';
import 'package:logistics_app/core/api/models/message_type.dart';
import 'package:logistics_app/core/api/models/notification_status.dart';
import 'package:logistics_app/core/api/models/notification_view.dart';

// Constructor de NotificationView de ejemplo para los tests de notificaciones.

NotificationView notificationView({
  String id = 'n1',
  String shipmentId = 'SHP-1',
  String? shipmentExternalId,
  MessageType messageType = MessageType.enRoute,
  NotificationStatus status = NotificationStatus.queued,
  Channel currentChannel = Channel.pushNtfy,
  String fcmTopic = 'topic-1',
  List<Channel> channels = const [Channel.pushNtfy, Channel.email],
  Map<String, int> attempts = const {},
}) => NotificationView(
  id: id,
  shipmentId: shipmentId,
  shipmentExternalId: shipmentExternalId,
  messageType: messageType,
  status: status,
  currentChannel: currentChannel,
  fcmTopic: fcmTopic,
  channels: channels,
  attempts: attempts,
);
