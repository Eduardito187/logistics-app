// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'destinations.dart';
import 'dispatch_line.dart';

part 'dispatch_lines_response.g.dart';

@JsonSerializable()
class DispatchLinesResponse {
  const DispatchLinesResponse({
    required this.orderReference,
    required this.destinations,
    required this.data,
  });

  factory DispatchLinesResponse.fromJson(Map<String, Object?> json) =>
      _$DispatchLinesResponseFromJson(json);

  /// Número/referencia legible del pedido
  @JsonKey(name: 'order_reference')
  final String orderReference;

  /// Resumen de grupos por envío/destino (para agrupar en la UI multishipping)
  final List<Destinations> destinations;
  final List<DispatchLine> data;

  Map<String, Object?> toJson() => _$DispatchLinesResponseToJson(this);
}
