// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Destination2 _$Destination2FromJson(Map<String, dynamic> json) => Destination2(
  type: json['type'] == null ? null : Type4.fromJson(json['type'] as String),
  name: json['name'] as String?,
  address: json['address'] as String?,
);

Map<String, dynamic> _$Destination2ToJson(Destination2 instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'address': instance.address,
    };
