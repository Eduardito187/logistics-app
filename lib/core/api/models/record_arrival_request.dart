// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'record_arrival_request.g.dart';

@JsonSerializable()
class RecordArrivalRequest {
  const RecordArrivalRequest({required this.asnId, this.carrierReference});

  factory RecordArrivalRequest.fromJson(Map<String, Object?> json) =>
      _$RecordArrivalRequestFromJson(json);

  @JsonKey(name: 'asn_id')
  final String asnId;
  @JsonKey(name: 'carrier_reference')
  final String? carrierReference;

  Map<String, Object?> toJson() => _$RecordArrivalRequestToJson(this);
}
