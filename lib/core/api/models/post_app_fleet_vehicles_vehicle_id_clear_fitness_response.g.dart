// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_fleet_vehicles_vehicle_id_clear_fitness_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppFleetVehiclesVehicleIdClearFitnessResponse
_$PostAppFleetVehiclesVehicleIdClearFitnessResponseFromJson(
  Map<String, dynamic> json,
) => PostAppFleetVehiclesVehicleIdClearFitnessResponse(
  data: json['data'] == null
      ? null
      : FleetClearVehicleFitnessData.fromJson(
          json['data'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PostAppFleetVehiclesVehicleIdClearFitnessResponseToJson(
  PostAppFleetVehiclesVehicleIdClearFitnessResponse instance,
) => <String, dynamic>{'data': instance.data};
