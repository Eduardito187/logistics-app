// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_address_parts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentAddressParts _$ShipmentAddressPartsFromJson(
  Map<String, dynamic> json,
) => ShipmentAddressParts(
  street: json['street'] as String?,
  number: json['number'] as String?,
  neighborhood: json['neighborhood'] as String?,
  reference: json['reference'] as String?,
  city: json['city'] as String?,
);

Map<String, dynamic> _$ShipmentAddressPartsToJson(
  ShipmentAddressParts instance,
) => <String, dynamic>{
  'street': instance.street,
  'number': instance.number,
  'neighborhood': instance.neighborhood,
  'reference': instance.reference,
  'city': instance.city,
};
