// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'refuel.dart';

part 'get_app_fleetops_refuels_response.g.dart';

@JsonSerializable()
class GetAppFleetopsRefuelsResponse {
  const GetAppFleetopsRefuelsResponse({required this.data});

  factory GetAppFleetopsRefuelsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetopsRefuelsResponseFromJson(json);

  final List<Refuel> data;

  Map<String, Object?> toJson() => _$GetAppFleetopsRefuelsResponseToJson(this);
}
