// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'document_expiry.dart';

part 'helper.g.dart';

@JsonSerializable()
class Helper {
  const Helper({this.id, this.name, this.phone, this.documents, this.active});

  factory Helper.fromJson(Map<String, Object?> json) => _$HelperFromJson(json);

  final String? id;
  final String? name;
  final String? phone;
  final List<DocumentExpiry>? documents;
  final bool? active;

  Map<String, Object?> toJson() => _$HelperToJson(this);
}
