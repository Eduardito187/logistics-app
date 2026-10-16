// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_carrier_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterCarrierRequest _$RegisterCarrierRequestFromJson(
  Map<String, dynamic> json,
) => RegisterCarrierRequest(
  name: json['name'] as String,
  taxId: json['tax_id'] as String,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => CarrierDocument.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RegisterCarrierRequestToJson(
  RegisterCarrierRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'tax_id': instance.taxId,
  'documents': instance.documents,
};
