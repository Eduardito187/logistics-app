// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_channels_promises_delivery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetChannelsPromisesDeliveryResponse
_$GetChannelsPromisesDeliveryResponseFromJson(Map<String, dynamic> json) =>
    GetChannelsPromisesDeliveryResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => MunicipalitySlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : MetaSealed.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetChannelsPromisesDeliveryResponseToJson(
  GetChannelsPromisesDeliveryResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
