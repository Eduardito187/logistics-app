// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'piece.g.dart';

@JsonSerializable()
class Piece {
  const Piece({required this.index, required this.total});

  factory Piece.fromJson(Map<String, Object?> json) => _$PieceFromJson(json);

  final int index;
  final int total;

  Map<String, Object?> toJson() => _$PieceToJson(this);
}
