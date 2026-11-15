// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_cart.dart';

part 'commerce_cart_response.g.dart';

@JsonSerializable()
class CommerceCartResponse {
  const CommerceCartResponse({required this.data});

  factory CommerceCartResponse.fromJson(Map<String, Object?> json) =>
      _$CommerceCartResponseFromJson(json);

  final CommerceCart data;

  Map<String, Object?> toJson() => _$CommerceCartResponseToJson(this);
}
