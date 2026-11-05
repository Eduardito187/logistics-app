// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch_lines_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispatchLinesResponse _$DispatchLinesResponseFromJson(
  Map<String, dynamic> json,
) => DispatchLinesResponse(
  orderReference: json['order_reference'] as String,
  destinations: (json['destinations'] as List<dynamic>)
      .map((e) => Destinations.fromJson(e as Map<String, dynamic>))
      .toList(),
  data: (json['data'] as List<dynamic>)
      .map((e) => DispatchLine.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DispatchLinesResponseToJson(
  DispatchLinesResponse instance,
) => <String, dynamic>{
  'order_reference': instance.orderReference,
  'destinations': instance.destinations,
  'data': instance.data,
};
