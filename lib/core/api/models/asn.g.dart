// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Asn _$AsnFromJson(Map<String, dynamic> json) => Asn(
  id: json['id'] as String,
  sellerId: json['seller_id'] as String,
  warehouseId: json['warehouse_id'] as String,
  status: AsnStatus.fromJson(json['status'] as String),
  lines: (json['lines'] as List<dynamic>)
      .map((e) => AsnLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  appointment: json['appointment'] == null
      ? null
      : AsnAppointment.fromJson(json['appointment'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AsnToJson(Asn instance) => <String, dynamic>{
  'id': instance.id,
  'seller_id': instance.sellerId,
  'warehouse_id': instance.warehouseId,
  'status': instance.status,
  'lines': instance.lines,
  'appointment': instance.appointment,
};
