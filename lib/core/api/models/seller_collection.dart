// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'pagination_meta.dart';
import 'seller.dart';

part 'seller_collection.g.dart';

@JsonSerializable()
class SellerCollection {
  const SellerCollection({required this.data, this.meta});

  factory SellerCollection.fromJson(Map<String, Object?> json) =>
      _$SellerCollectionFromJson(json);

  final List<Seller> data;
  final PaginationMeta? meta;

  Map<String, Object?> toJson() => _$SellerCollectionToJson(this);
}
