// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lines.dart';

part 'announce_asn_request.g.dart';

@JsonSerializable()
class AnnounceAsnRequest {
  const AnnounceAsnRequest({
    required this.sellerId,
    required this.warehouseId,
    required this.lines,
  });

  factory AnnounceAsnRequest.fromJson(Map<String, Object?> json) =>
      _$AnnounceAsnRequestFromJson(json);

  @JsonKey(name: 'seller_id')
  final String sellerId;
  @JsonKey(name: 'warehouse_id')
  final String warehouseId;
  final List<Lines> lines;

  Map<String, Object?> toJson() => _$AnnounceAsnRequestToJson(this);
}
