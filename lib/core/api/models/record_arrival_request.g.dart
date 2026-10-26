// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_arrival_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordArrivalRequest _$RecordArrivalRequestFromJson(
  Map<String, dynamic> json,
) => RecordArrivalRequest(
  asnId: json['asn_id'] as String,
  carrierReference: json['carrier_reference'] as String?,
);

Map<String, dynamic> _$RecordArrivalRequestToJson(
  RecordArrivalRequest instance,
) => <String, dynamic>{
  'asn_id': instance.asnId,
  'carrier_reference': instance.carrierReference,
};
