// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_printers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppPrintersResponse _$GetAppPrintersResponseFromJson(
  Map<String, dynamic> json,
) => GetAppPrintersResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => NetworkPrinter.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppPrintersResponseToJson(
  GetAppPrintersResponse instance,
) => <String, dynamic>{'data': instance.data};
