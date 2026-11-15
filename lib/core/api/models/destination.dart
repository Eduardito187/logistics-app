// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'type4.dart';

part 'destination.g.dart';

@JsonSerializable()
class Destination {
  const Destination({this.type, this.name, this.nodeCode, this.nodeId});

  factory Destination.fromJson(Map<String, Object?> json) =>
      _$DestinationFromJson(json);

  final Type4? type;
  final String? name;
  @JsonKey(name: 'node_code')
  final String? nodeCode;
  @JsonKey(name: 'node_id')
  final String? nodeId;

  Map<String, Object?> toJson() => _$DestinationToJson(this);
}
