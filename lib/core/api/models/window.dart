// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'window.g.dart';

@JsonSerializable()
class Window {
  const Window({this.from, this.to, this.open});

  factory Window.fromJson(Map<String, Object?> json) => _$WindowFromJson(json);

  final DateTime? from;
  final DateTime? to;
  final bool? open;

  Map<String, Object?> toJson() => _$WindowToJson(this);
}
