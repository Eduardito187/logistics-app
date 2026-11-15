// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_user_carrier.g.dart';

@JsonSerializable()
class AppUserCarrier {
  const AppUserCarrier({
    required this.id,
    required this.name,
    required this.taxId,
  });

  factory AppUserCarrier.fromJson(Map<String, Object?> json) =>
      _$AppUserCarrierFromJson(json);

  final String id;
  final String name;
  @JsonKey(name: 'tax_id')
  final String taxId;

  Map<String, Object?> toJson() => _$AppUserCarrierToJson(this);
}
