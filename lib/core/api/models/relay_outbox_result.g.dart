// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_outbox_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelayOutboxResult _$RelayOutboxResultFromJson(Map<String, dynamic> json) =>
    RelayOutboxResult(
      pulled: (json['pulled'] as num).toInt(),
      dispatched: (json['dispatched'] as num).toInt(),
      failed: (json['failed'] as num).toInt(),
      deadLettered: (json['dead_lettered'] as num).toInt(),
    );

Map<String, dynamic> _$RelayOutboxResultToJson(RelayOutboxResult instance) =>
    <String, dynamic>{
      'pulled': instance.pulled,
      'dispatched': instance.dispatched,
      'failed': instance.failed,
      'dead_lettered': instance.deadLettered,
    };
