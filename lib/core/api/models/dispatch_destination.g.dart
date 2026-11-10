// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch_destination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispatchDestination _$DispatchDestinationFromJson(Map<String, dynamic> json) =>
    DispatchDestination(
      type: json['type'] == null
          ? null
          : DispatchDestinationType.fromJson(json['type'] as String),
      name: json['name'] as String?,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$DispatchDestinationToJson(
  DispatchDestination instance,
) => <String, dynamic>{
  'type': instance.type,
  'name': instance.name,
  'address': instance.address,
};
