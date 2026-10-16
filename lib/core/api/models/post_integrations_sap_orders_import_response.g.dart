// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_integrations_sap_orders_import_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostIntegrationsSapOrdersImportResponse
_$PostIntegrationsSapOrdersImportResponseFromJson(Map<String, dynamic> json) =>
    PostIntegrationsSapOrdersImportResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => ImportedSapOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: Meta6.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PostIntegrationsSapOrdersImportResponseToJson(
  PostIntegrationsSapOrdersImportResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
