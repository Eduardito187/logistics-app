// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'staff_photo_kind.dart';

part 'staff_photo.g.dart';

@JsonSerializable()
class StaffPhoto {
  const StaffPhoto({this.kind, this.url, this.at, this.label});

  factory StaffPhoto.fromJson(Map<String, Object?> json) =>
      _$StaffPhotoFromJson(json);

  final StaffPhotoKind? kind;
  final String? url;
  final DateTime? at;
  final String? label;

  Map<String, Object?> toJson() => _$StaffPhotoToJson(this);
}
