// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'departure.dart';

part 'get_app_fleetops_departures_response.g.dart';

@JsonSerializable()
class GetAppFleetopsDeparturesResponse {
  const GetAppFleetopsDeparturesResponse({required this.data});

  factory GetAppFleetopsDeparturesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsDeparturesResponseFromJson(json);

  final List<Departure> data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsDeparturesResponseToJson(this);
}
