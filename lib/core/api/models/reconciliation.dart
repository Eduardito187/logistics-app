// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'missing2.dart';
import 'surplus2.dart';

part 'reconciliation.g.dart';

@JsonSerializable()
class Reconciliation {
  const Reconciliation({
    this.notes,
    this.photoPath,
    this.missing,
    this.surplus,
  });

  factory Reconciliation.fromJson(Map<String, Object?> json) =>
      _$ReconciliationFromJson(json);

  final String? notes;
  @JsonKey(name: 'photo_path')
  final String? photoPath;
  final List<Missing2>? missing;
  final List<Surplus2>? surplus;

  Map<String, Object?> toJson() => _$ReconciliationToJson(this);
}
