// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'close_transfer_with_shortage_request.g.dart';

@JsonSerializable()
class CloseTransferWithShortageRequest {
  const CloseTransferWithShortageRequest({required this.reason});

  factory CloseTransferWithShortageRequest.fromJson(
    Map<String, Object?> json,
  ) => _$CloseTransferWithShortageRequestFromJson(json);

  /// Motivo por el que la oficina cierra el traspaso sin la conciliación de la tienda.
  final String reason;

  Map<String, Object?> toJson() =>
      _$CloseTransferWithShortageRequestToJson(this);
}
