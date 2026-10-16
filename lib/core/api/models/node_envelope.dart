// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'node.dart';

part 'node_envelope.g.dart';

@JsonSerializable()
class NodeEnvelope {
  const NodeEnvelope({required this.data});

  factory NodeEnvelope.fromJson(Map<String, Object?> json) =>
      _$NodeEnvelopeFromJson(json);

  final Node data;

  Map<String, Object?> toJson() => _$NodeEnvelopeToJson(this);
}
