// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surplus.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Surplus _$SurplusFromJson(Map<String, dynamic> json) => Surplus(
  unitId: json['unit_id'] as String,
  belongsToShipmentId: json['belongs_to_shipment_id'] as String?,
);

Map<String, dynamic> _$SurplusToJson(Surplus instance) => <String, dynamic>{
  'unit_id': instance.unitId,
  'belongs_to_shipment_id': instance.belongsToShipmentId,
};
