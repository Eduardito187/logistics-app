// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initiate_return_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitiateReturnRequest _$InitiateReturnRequestFromJson(
  Map<String, dynamic> json,
) => InitiateReturnRequest(
  originalReference: json['original_reference'] as String,
  warehouseId: json['warehouse_id'] as String,
  kind: ReturnOrderKind.fromJson(json['kind'] as String),
  lines: (json['lines'] as List<dynamic>)
      .map((e) => ReturnLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  ownerPartyId: json['owner_party_id'] as String?,
);

Map<String, dynamic> _$InitiateReturnRequestToJson(
  InitiateReturnRequest instance,
) => <String, dynamic>{
  'original_reference': instance.originalReference,
  'warehouse_id': instance.warehouseId,
  'kind': instance.kind,
  'owner_party_id': instance.ownerPartyId,
  'lines': instance.lines,
};
