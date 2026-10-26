// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_to_promise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailableToPromise _$AvailableToPromiseFromJson(Map<String, dynamic> json) =>
    AvailableToPromise(
      warehouseId: json['warehouse_id'] as String,
      sku: json['sku'] as String,
      ownerPartyId: json['owner_party_id'] as String?,
      availableToPromise: (json['available_to_promise'] as num).toInt(),
    );

Map<String, dynamic> _$AvailableToPromiseToJson(AvailableToPromise instance) =>
    <String, dynamic>{
      'warehouse_id': instance.warehouseId,
      'sku': instance.sku,
      'owner_party_id': instance.ownerPartyId,
      'available_to_promise': instance.availableToPromise,
    };
