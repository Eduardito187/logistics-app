// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reprint_labels_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReprintLabelsRequest _$ReprintLabelsRequestFromJson(
  Map<String, dynamic> json,
) => ReprintLabelsRequest(
  origin: json['origin'] as String,
  destination: json['destination'] as String,
  lines: (json['lines'] as List<dynamic>)
      .map((e) => EmitLabelLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  reason: json['reason'] as String,
);

Map<String, dynamic> _$ReprintLabelsRequestToJson(
  ReprintLabelsRequest instance,
) => <String, dynamic>{
  'origin': instance.origin,
  'destination': instance.destination,
  'lines': instance.lines,
  'reason': instance.reason,
};
