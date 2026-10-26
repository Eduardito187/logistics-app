// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'asn.dart';

part 'asn_collection.g.dart';

@JsonSerializable()
class AsnCollection {
  const AsnCollection({required this.data});

  factory AsnCollection.fromJson(Map<String, Object?> json) =>
      _$AsnCollectionFromJson(json);

  final List<Asn> data;

  Map<String, Object?> toJson() => _$AsnCollectionToJson(this);
}
