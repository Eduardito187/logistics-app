// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_ack.g.dart';

/// Acknowledgement of an accepted asynchronous write (202).
@JsonSerializable()
class CommerceAck {
  const CommerceAck({required this.accepted});

  factory CommerceAck.fromJson(Map<String, Object?> json) =>
      _$CommerceAckFromJson(json);

  final bool accepted;

  Map<String, Object?> toJson() => _$CommerceAckToJson(this);
}
