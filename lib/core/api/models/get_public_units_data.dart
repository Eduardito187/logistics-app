// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'public_unit.dart';

part 'get_public_units_data.g.dart';

@JsonSerializable()
class GetPublicUnitsData {
  const GetPublicUnitsData({required this.units});

  factory GetPublicUnitsData.fromJson(Map<String, Object?> json) =>
      _$GetPublicUnitsDataFromJson(json);

  final List<PublicUnit> units;

  Map<String, Object?> toJson() => _$GetPublicUnitsDataToJson(this);
}
