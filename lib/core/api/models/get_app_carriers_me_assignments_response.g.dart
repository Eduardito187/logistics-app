// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_carriers_me_assignments_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppCarriersMeAssignmentsResponse
_$GetAppCarriersMeAssignmentsResponseFromJson(Map<String, dynamic> json) =>
    GetAppCarriersMeAssignmentsResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => CarrierAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetAppCarriersMeAssignmentsResponseToJson(
  GetAppCarriersMeAssignmentsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
