// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data11.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data11 _$Data11FromJson(Map<String, dynamic> json) => Data11(
  units: (json['units'] as List<dynamic>)
      .map((e) => PublicUnit.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Data11ToJson(Data11 instance) => <String, dynamic>{
  'units': instance.units,
};
