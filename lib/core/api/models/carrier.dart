// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_document.dart';
import 'carrier_status.dart';

part 'carrier.g.dart';

@JsonSerializable()
class Carrier {
  const Carrier({
    required this.id,
    required this.name,
    required this.taxId,
    required this.status,
    required this.ratingCount,
    required this.documents,
    this.averageRating,
  });

  factory Carrier.fromJson(Map<String, Object?> json) =>
      _$CarrierFromJson(json);

  final String id;
  final String name;
  @JsonKey(name: 'tax_id')
  final String taxId;
  final CarrierStatus status;
  @JsonKey(name: 'average_rating')
  final double? averageRating;
  @JsonKey(name: 'rating_count')
  final int ratingCount;
  final List<CarrierDocument> documents;

  Map<String, Object?> toJson() => _$CarrierToJson(this);
}
