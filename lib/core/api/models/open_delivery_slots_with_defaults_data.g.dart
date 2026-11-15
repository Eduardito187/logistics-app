// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_delivery_slots_with_defaults_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenDeliverySlotsWithDefaultsData _$OpenDeliverySlotsWithDefaultsDataFromJson(
  Map<String, dynamic> json,
) => OpenDeliverySlotsWithDefaultsData(
  status: OpenDeliverySlotsWithDefaultsDataStatus.fromJson(
    json['status'] as String,
  ),
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  weekdays: (json['weekdays'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  allMunicipalities: json['all_municipalities'] as bool,
  municipalitiesCount: (json['municipalities_count'] as num).toInt(),
  municipalityIds: (json['municipality_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  windows: (json['windows'] as List<dynamic>)
      .map(
        (e) => DeliveryCalendarActivationWindow.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
);

Map<String, dynamic> _$OpenDeliverySlotsWithDefaultsDataToJson(
  OpenDeliverySlotsWithDefaultsData instance,
) => <String, dynamic>{
  'status': instance.status,
  'from': instance.from.toIso8601String(),
  'to': instance.to.toIso8601String(),
  'weekdays': instance.weekdays,
  'all_municipalities': instance.allMunicipalities,
  'municipalities_count': instance.municipalitiesCount,
  'municipality_ids': instance.municipalityIds,
  'windows': instance.windows,
};
