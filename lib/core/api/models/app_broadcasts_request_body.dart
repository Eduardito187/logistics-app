// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'audience.dart';

part 'app_broadcasts_request_body.g.dart';

@JsonSerializable()
class AppBroadcastsRequestBody {
  const AppBroadcastsRequestBody({
    required this.audience,
    required this.title,
    required this.body,
    this.link,
  });

  factory AppBroadcastsRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppBroadcastsRequestBodyFromJson(json);

  /// Al menos una audiencia efectiva: role, node_id o user_ids no vacío. `role` y `node_id` juntos se combinan con AND; `user_ids` se suma. El push FCM del aviso lleva data {type: "inbox", id}.
  final Audience audience;
  final String title;
  final String body;

  /// Ruta interna de la app a abrir al tocar el aviso
  final String? link;

  Map<String, Object?> toJson() => _$AppBroadcastsRequestBodyToJson(this);
}
