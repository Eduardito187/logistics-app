// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_updated_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationsUpdatedEvent _$NotificationsUpdatedEventFromJson(
  Map<String, dynamic> json,
) => NotificationsUpdatedEvent(
  scope: NotificationsUpdatedEventScope.fromJson(json['scope'] as String),
);

Map<String, dynamic> _$NotificationsUpdatedEventToJson(
  NotificationsUpdatedEvent instance,
) => <String, dynamic>{'scope': instance.scope};
