// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'network_printer.dart';

part 'get_app_printers_response.g.dart';

@JsonSerializable()
class GetAppPrintersResponse {
  const GetAppPrintersResponse({required this.data});

  factory GetAppPrintersResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppPrintersResponseFromJson(json);

  final List<NetworkPrinter> data;

  Map<String, Object?> toJson() => _$GetAppPrintersResponseToJson(this);
}
