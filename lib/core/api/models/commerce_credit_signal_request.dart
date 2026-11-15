// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_credit_signal_request.g.dart';

/// Señal de crédito (firma de contrato / pago de inicial) reportada por el POS/sistema de crédito.
@JsonSerializable()
class CommerceCreditSignalRequest {
  const CommerceCreditSignalRequest({this.reference});

  factory CommerceCreditSignalRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceCreditSignalRequestFromJson(json);

  /// Referencia externa opcional del POS/sistema de crédito (nro. de contrato, comprobante).
  final String? reference;

  Map<String, Object?> toJson() => _$CommerceCreditSignalRequestToJson(this);
}
