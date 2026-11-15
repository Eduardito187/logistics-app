// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'summary.g.dart';

@JsonSerializable()
class Summary {
  const Summary({this.updated, this.notFound, this.invalid});

  factory Summary.fromJson(Map<String, Object?> json) =>
      _$SummaryFromJson(json);

  final int? updated;
  @JsonKey(name: 'not_found')
  final int? notFound;
  final int? invalid;

  Map<String, Object?> toJson() => _$SummaryToJson(this);
}
