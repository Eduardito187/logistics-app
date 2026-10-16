// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'emit_label_line.dart';

part 'reprint_labels_request.g.dart';

@JsonSerializable()
class ReprintLabelsRequest {
  const ReprintLabelsRequest({
    required this.origin,
    required this.destination,
    required this.lines,
    required this.reason,
  });

  factory ReprintLabelsRequest.fromJson(Map<String, Object?> json) =>
      _$ReprintLabelsRequestFromJson(json);

  /// Nodo de origen
  final String origin;

  /// Nodo de destino
  final String destination;
  final List<EmitLabelLine> lines;

  /// Motivo de la reimpresión; queda registrado al revocar el lote anterior
  final String reason;

  Map<String, Object?> toJson() => _$ReprintLabelsRequestToJson(this);
}
