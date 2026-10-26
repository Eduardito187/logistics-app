// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_portal_asn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SellerPortalAsn _$SellerPortalAsnFromJson(Map<String, dynamic> json) =>
    SellerPortalAsn(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      warehouseId: json['warehouse_id'] as String,
      status: SellerPortalAsnStatus.fromJson(json['status'] as String),
      appointmentDate: json['appointment_date'] == null
          ? null
          : DateTime.parse(json['appointment_date'] as String),
      appointmentStart: json['appointment_start'] as String?,
      appointmentEnd: json['appointment_end'] as String?,
    );

Map<String, dynamic> _$SellerPortalAsnToJson(SellerPortalAsn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seller_id': instance.sellerId,
      'warehouse_id': instance.warehouseId,
      'status': instance.status,
      'appointment_date': instance.appointmentDate?.toIso8601String(),
      'appointment_start': instance.appointmentStart,
      'appointment_end': instance.appointmentEnd,
    };
