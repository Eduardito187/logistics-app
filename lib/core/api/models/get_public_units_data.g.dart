// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_public_units_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPublicUnitsData _$GetPublicUnitsDataFromJson(Map<String, dynamic> json) =>
    GetPublicUnitsData(
      units: (json['units'] as List<dynamic>)
          .map((e) => PublicUnit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetPublicUnitsDataToJson(GetPublicUnitsData instance) =>
    <String, dynamic>{'units': instance.units};
