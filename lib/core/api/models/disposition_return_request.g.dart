// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disposition_return_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispositionReturnRequest _$DispositionReturnRequestFromJson(
  Map<String, dynamic> json,
) => DispositionReturnRequest(
  disposition: ReturnDisposition.fromJson(json['disposition'] as String),
);

Map<String, dynamic> _$DispositionReturnRequestToJson(
  DispositionReturnRequest instance,
) => <String, dynamic>{'disposition': instance.disposition};
