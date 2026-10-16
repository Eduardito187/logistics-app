// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'emit_label_line.dart';

part 'emit_labels_request.g.dart';

@JsonSerializable()
class EmitLabelsRequest {
  const EmitLabelsRequest({
    required this.origin,
    required this.destination,
    required this.lines,
  });

  factory EmitLabelsRequest.fromJson(Map<String, Object?> json) =>
      _$EmitLabelsRequestFromJson(json);

  /// Nodo de origen
  final String origin;

  /// Nodo de destino
  final String destination;
  final List<EmitLabelLine> lines;

  Map<String, Object?> toJson() => _$EmitLabelsRequestToJson(this);
}
