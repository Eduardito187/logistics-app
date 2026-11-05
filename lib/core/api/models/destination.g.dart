// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Destination _$DestinationFromJson(Map<String, dynamic> json) => Destination(
  type: json['type'] == null ? null : Type3.fromJson(json['type'] as String),
  name: json['name'] as String?,
  address: json['address'] as String?,
);

Map<String, dynamic> _$DestinationToJson(Destination instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'address': instance.address,
    };
