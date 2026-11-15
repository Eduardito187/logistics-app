// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier_assignment_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarrierAssignmentUnit _$CarrierAssignmentUnitFromJson(
  Map<String, dynamic> json,
) => CarrierAssignmentUnit(
  unitId: json['unit_id'] as String,
  sku: json['sku'] as String,
  productName: json['product_name'] as String,
  productLabel: json['product_label'] as String,
  pieceIndex: (json['piece_index'] as num).toInt(),
  pieceTotal: (json['piece_total'] as num).toInt(),
);

Map<String, dynamic> _$CarrierAssignmentUnitToJson(
  CarrierAssignmentUnit instance,
) => <String, dynamic>{
  'unit_id': instance.unitId,
  'sku': instance.sku,
  'product_name': instance.productName,
  'product_label': instance.productLabel,
  'piece_index': instance.pieceIndex,
  'piece_total': instance.pieceTotal,
};
