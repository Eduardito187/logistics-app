// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'seller_settlement_mark_paid_request.g.dart';

@JsonSerializable()
class SellerSettlementMarkPaidRequest {
  const SellerSettlementMarkPaidRequest({required this.paymentReference});

  factory SellerSettlementMarkPaidRequest.fromJson(Map<String, Object?> json) =>
      _$SellerSettlementMarkPaidRequestFromJson(json);

  @JsonKey(name: 'payment_reference')
  final String paymentReference;

  Map<String, Object?> toJson() =>
      _$SellerSettlementMarkPaidRequestToJson(this);
}
