// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_network_node_data.g.dart';

@JsonSerializable()
class RegisterNetworkNodeData {
  const RegisterNetworkNodeData({required this.code});

  factory RegisterNetworkNodeData.fromJson(Map<String, Object?> json) =>
      _$RegisterNetworkNodeDataFromJson(json);

  final String code;

  Map<String, Object?> toJson() => _$RegisterNetworkNodeDataToJson(this);
}
