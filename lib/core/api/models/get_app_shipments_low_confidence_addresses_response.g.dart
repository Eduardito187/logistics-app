// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_shipments_low_confidence_addresses_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppShipmentsLowConfidenceAddressesResponse
_$GetAppShipmentsLowConfidenceAddressesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppShipmentsLowConfidenceAddressesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : MetaSealed.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GetAppShipmentsLowConfidenceAddressesResponseToJson(
  GetAppShipmentsLowConfidenceAddressesResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
