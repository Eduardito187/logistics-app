// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_shipment_units_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetShipmentUnitsData _$GetShipmentUnitsDataFromJson(
  Map<String, dynamic> json,
) => GetShipmentUnitsData(
  shipmentId: json['shipment_id'] as String,
  units: (json['units'] as List<dynamic>)
      .map((e) => UnitTracking.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetShipmentUnitsDataToJson(
  GetShipmentUnitsData instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'units': instance.units,
};
