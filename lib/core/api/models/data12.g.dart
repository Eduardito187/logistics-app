// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data12.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data12 _$Data12FromJson(Map<String, dynamic> json) => Data12(
  units: (json['units'] as List<dynamic>)
      .map((e) => PublicUnit.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Data12ToJson(Data12 instance) => <String, dynamic>{
  'units': instance.units,
};
