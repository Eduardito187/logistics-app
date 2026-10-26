// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'label_received_units_request.g.dart';

@JsonSerializable()
class LabelReceivedUnitsRequest {
  const LabelReceivedUnitsRequest({required this.asnId});

  factory LabelReceivedUnitsRequest.fromJson(Map<String, Object?> json) =>
      _$LabelReceivedUnitsRequestFromJson(json);

  @JsonKey(name: 'asn_id')
  final String asnId;

  Map<String, Object?> toJson() => _$LabelReceivedUnitsRequestToJson(this);
}
