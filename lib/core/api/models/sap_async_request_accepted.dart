// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'meta4.dart';
import 'sap_async_request_accepted_data.dart';

part 'sap_async_request_accepted.g.dart';

/// Respuesta de un pedido asíncrono hacia SAP (el trabajo quedó encolado en la cola `sap`).
@JsonSerializable()
class SapAsyncRequestAccepted {
  const SapAsyncRequestAccepted({required this.data, required this.meta});

  factory SapAsyncRequestAccepted.fromJson(Map<String, Object?> json) =>
      _$SapAsyncRequestAcceptedFromJson(json);

  final SapAsyncRequestAcceptedData data;
  final Meta4 meta;

  Map<String, Object?> toJson() => _$SapAsyncRequestAcceptedToJson(this);
}
