// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_label_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyLabelRequest _$VerifyLabelRequestFromJson(Map<String, dynamic> json) =>
    VerifyLabelRequest(
      payload: json['payload'] as String,
      signature: json['signature'] as String,
      keyId: (json['key_id'] as num).toInt(),
    );

Map<String, dynamic> _$VerifyLabelRequestToJson(VerifyLabelRequest instance) =>
    <String, dynamic>{
      'payload': instance.payload,
      'signature': instance.signature,
      'key_id': instance.keyId,
    };
