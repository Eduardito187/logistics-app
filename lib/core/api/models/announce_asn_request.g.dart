// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announce_asn_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnounceAsnRequest _$AnnounceAsnRequestFromJson(Map<String, dynamic> json) =>
    AnnounceAsnRequest(
      sellerId: json['seller_id'] as String,
      warehouseId: json['warehouse_id'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => Lines.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnnounceAsnRequestToJson(AnnounceAsnRequest instance) =>
    <String, dynamic>{
      'seller_id': instance.sellerId,
      'warehouse_id': instance.warehouseId,
      'lines': instance.lines,
    };
