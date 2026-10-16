// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_devices_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppDevicesResponse _$GetAppDevicesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppDevicesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => DeviceListItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppDevicesResponseToJson(
  GetAppDevicesResponse instance,
) => <String, dynamic>{'data': instance.data};
