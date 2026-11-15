// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enqueue_stock_transfer_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnqueueStockTransferData _$EnqueueStockTransferDataFromJson(
  Map<String, dynamic> json,
) => EnqueueStockTransferData(
  eventId: json['event_id'] as String,
  shipmentRef: json['shipment_ref'] as String,
  status: EnqueueStockTransferDataStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$EnqueueStockTransferDataToJson(
  EnqueueStockTransferData instance,
) => <String, dynamic>{
  'event_id': instance.eventId,
  'shipment_ref': instance.shipmentRef,
  'status': instance.status,
};
