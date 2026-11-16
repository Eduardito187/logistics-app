// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notifications_updated_event_scope.dart';

part 'notifications_updated_event.g.dart';

/// Carga del evento `notifications.updated` en el canal `private-user.{id}`. Solo es la señal para volver a pedir GET /app/notifications y /app/notifications/all (el no-leído sale de meta.unread_count); el contenido nunca viaja por el socket. Llega unos 3 s después del cambio.
@JsonSerializable()
class NotificationsUpdatedEvent {
  const NotificationsUpdatedEvent({required this.scope});

  factory NotificationsUpdatedEvent.fromJson(Map<String, Object?> json) =>
      _$NotificationsUpdatedEventFromJson(json);

  /// feed = cambió el log (nueva, enviada, escalada, suprimida); user = cambió el estado de lectura del propio usuario (leída / leer todas).
  final NotificationsUpdatedEventScope scope;

  Map<String, Object?> toJson() => _$NotificationsUpdatedEventToJson(this);
}
