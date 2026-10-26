// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller.dart';

part 'seller_envelope.g.dart';

@JsonSerializable()
class SellerEnvelope {
  const SellerEnvelope({required this.data});

  factory SellerEnvelope.fromJson(Map<String, Object?> json) =>
      _$SellerEnvelopeFromJson(json);

  final Seller data;

  Map<String, Object?> toJson() => _$SellerEnvelopeToJson(this);
}
