// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'helpers.g.dart';

@JsonSerializable()
class Helpers {
  const Helpers({required this.id, required this.name});

  factory Helpers.fromJson(Map<String, Object?> json) =>
      _$HelpersFromJson(json);

  final String id;
  final String? name;

  Map<String, Object?> toJson() => _$HelpersToJson(this);
}
