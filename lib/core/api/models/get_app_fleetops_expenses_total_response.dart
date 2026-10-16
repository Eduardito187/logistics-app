// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_app_fleetops_expenses_total_response.g.dart';

@JsonSerializable()
class GetAppFleetopsExpensesTotalResponse {
  const GetAppFleetopsExpensesTotalResponse({required this.data});

  factory GetAppFleetopsExpensesTotalResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsExpensesTotalResponseFromJson(json);

  final dynamic data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsExpensesTotalResponseToJson(this);
}
