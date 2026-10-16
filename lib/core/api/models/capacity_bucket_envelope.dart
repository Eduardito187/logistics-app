// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'capacity_bucket.dart';

part 'capacity_bucket_envelope.g.dart';

@JsonSerializable()
class CapacityBucketEnvelope {
  const CapacityBucketEnvelope({required this.data});

  factory CapacityBucketEnvelope.fromJson(Map<String, Object?> json) =>
      _$CapacityBucketEnvelopeFromJson(json);

  final CapacityBucket data;

  Map<String, Object?> toJson() => _$CapacityBucketEnvelopeToJson(this);
}
