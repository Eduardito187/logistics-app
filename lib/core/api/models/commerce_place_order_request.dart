// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_order_line.dart';
import 'commerce_place_order_request_financing.dart';
import 'commerce_ship_to.dart';

part 'commerce_place_order_request.g.dart';

@JsonSerializable()
class CommercePlaceOrderRequest {
  const CommercePlaceOrderRequest({
    required this.shipTo,
    required this.lines,
    this.financing = CommercePlaceOrderRequestFinancing.cash,
    this.customerId,
    this.currency,
  });

  factory CommercePlaceOrderRequest.fromJson(Map<String, Object?> json) =>
      _$CommercePlaceOrderRequestFromJson(json);

  @JsonKey(name: 'customer_id')
  final String? customerId;

  /// ISO 4217 code; defaults to BOB when omitted.
  final String? currency;

  /// Forma de financiamiento. Determina qué habilita el paso a procesando: contado = pago capturado; crédito sin inicial = firma de contrato; crédito con inicial = firma de contrato + pago del inicial.
  final CommercePlaceOrderRequestFinancing financing;
  @JsonKey(name: 'ship_to')
  final CommerceShipTo shipTo;
  final List<CommerceOrderLine> lines;

  Map<String, Object?> toJson() => _$CommercePlaceOrderRequestToJson(this);
}
