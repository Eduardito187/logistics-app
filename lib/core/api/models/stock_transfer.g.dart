// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockTransfer _$StockTransferFromJson(Map<String, dynamic> json) =>
    StockTransfer(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      shipmentRef: json['shipment_ref'] as String,
      material: json['material'] as String,
      center: json['center'] as String,
      warehouse: json['warehouse'] as String,
      quantity: (json['quantity'] as num).toInt(),
      status: StockTransferStatus.fromJson(json['status'] as String),
      lastError: json['last_error'] as String?,
    );

Map<String, dynamic> _$StockTransferToJson(StockTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'shipment_ref': instance.shipmentRef,
      'material': instance.material,
      'center': instance.center,
      'warehouse': instance.warehouse,
      'quantity': instance.quantity,
      'status': instance.status,
      'last_error': instance.lastError,
    };
