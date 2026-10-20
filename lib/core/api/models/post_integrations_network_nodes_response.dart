// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data19.dart';

part 'post_integrations_network_nodes_response.g.dart';

@JsonSerializable()
class PostIntegrationsNetworkNodesResponse {
  const PostIntegrationsNetworkNodesResponse({required this.data});

  factory PostIntegrationsNetworkNodesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsNetworkNodesResponseFromJson(json);

  final Data19 data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsNetworkNodesResponseToJson(this);
}
