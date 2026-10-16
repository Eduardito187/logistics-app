// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipment.dart';
import 'meta_sealed.dart';

part 'get_app_shipments_low_confidence_addresses_response.g.dart';

@JsonSerializable()
class GetAppShipmentsLowConfidenceAddressesResponse {
  const GetAppShipmentsLowConfidenceAddressesResponse({
    required this.data,
    this.meta,
  });

  factory GetAppShipmentsLowConfidenceAddressesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppShipmentsLowConfidenceAddressesResponseFromJson(json);

  final List<Shipment> data;
  final MetaSealed? meta;

  Map<String, Object?> toJson() =>
      _$GetAppShipmentsLowConfidenceAddressesResponseToJson(this);
}
