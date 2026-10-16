// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enqueue_stock_transfer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnqueueStockTransferRequest _$EnqueueStockTransferRequestFromJson(
  Map<String, dynamic> json,
) => EnqueueStockTransferRequest(
  eventId: json['event_id'] as String,
  shipmentRef: json['shipment_ref'] as String,
  sku: json['sku'] as String,
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$EnqueueStockTransferRequestToJson(
  EnqueueStockTransferRequest instance,
) => <String, dynamic>{
  'event_id': instance.eventId,
  'shipment_ref': instance.shipmentRef,
  'sku': instance.sku,
  'quantity': instance.quantity,
};
