// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user_carrier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUserCarrier _$AppUserCarrierFromJson(Map<String, dynamic> json) =>
    AppUserCarrier(
      id: json['id'] as String,
      name: json['name'] as String,
      taxId: json['tax_id'] as String,
    );

Map<String, dynamic> _$AppUserCarrierToJson(AppUserCarrier instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tax_id': instance.taxId,
    };
