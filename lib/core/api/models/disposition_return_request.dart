// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_disposition.dart';

part 'disposition_return_request.g.dart';

@JsonSerializable()
class DispositionReturnRequest {
  const DispositionReturnRequest({required this.disposition});

  factory DispositionReturnRequest.fromJson(Map<String, Object?> json) =>
      _$DispositionReturnRequestFromJson(json);

  final ReturnDisposition disposition;

  Map<String, Object?> toJson() => _$DispositionReturnRequestToJson(this);
}
