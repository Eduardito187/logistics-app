// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'departure.dart';

part 'get_app_fleetops_departures_departure_id_response.g.dart';

@JsonSerializable()
class GetAppFleetopsDeparturesDepartureIdResponse {
  const GetAppFleetopsDeparturesDepartureIdResponse({required this.data});

  factory GetAppFleetopsDeparturesDepartureIdResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsDeparturesDepartureIdResponseFromJson(json);

  final Departure data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsDeparturesDepartureIdResponseToJson(this);
}
