// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meta9.dart';
import 'promise_offer.dart';

part 'promise_offer_collection.g.dart';

@JsonSerializable()
class PromiseOfferCollection {
  const PromiseOfferCollection({required this.data, required this.meta});

  factory PromiseOfferCollection.fromJson(Map<String, Object?> json) =>
      _$PromiseOfferCollectionFromJson(json);

  final List<PromiseOffer> data;
  final Meta9 meta;

  Map<String, Object?> toJson() => _$PromiseOfferCollectionToJson(this);
}
