// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emit_labels_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmitLabelsRequest _$EmitLabelsRequestFromJson(Map<String, dynamic> json) =>
    EmitLabelsRequest(
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => EmitLabelLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EmitLabelsRequestToJson(EmitLabelsRequest instance) =>
    <String, dynamic>{
      'origin': instance.origin,
      'destination': instance.destination,
      'lines': instance.lines,
    };
