// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status10.dart';

part 'results.g.dart';

@JsonSerializable()
class Results {
  const Results({required this.sku, required this.status, this.message});

  factory Results.fromJson(Map<String, Object?> json) =>
      _$ResultsFromJson(json);

  final String sku;
  final Status10 status;
  final String? message;

  Map<String, Object?> toJson() => _$ResultsToJson(this);
}
