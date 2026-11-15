// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_update_item_qty_request.g.dart';

@JsonSerializable()
class CommerceUpdateItemQtyRequest {
  const CommerceUpdateItemQtyRequest({required this.quantity});

  factory CommerceUpdateItemQtyRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceUpdateItemQtyRequestFromJson(json);

  /// New quantity; 0 removes the line.
  final int quantity;

  Map<String, Object?> toJson() => _$CommerceUpdateItemQtyRequestToJson(this);
}
