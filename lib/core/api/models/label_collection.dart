// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'emitted_label.dart';

part 'label_collection.g.dart';

@JsonSerializable()
class LabelCollection {
  const LabelCollection({required this.data});

  factory LabelCollection.fromJson(Map<String, Object?> json) =>
      _$LabelCollectionFromJson(json);

  final List<EmittedLabel> data;

  Map<String, Object?> toJson() => _$LabelCollectionToJson(this);
}
