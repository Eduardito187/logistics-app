// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acknowledge_stock_transfer_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcknowledgeStockTransferData _$AcknowledgeStockTransferDataFromJson(
  Map<String, dynamic> json,
) => AcknowledgeStockTransferData(
  eventId: json['event_id'] as String,
  status: AcknowledgeStockTransferDataStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$AcknowledgeStockTransferDataToJson(
  AcknowledgeStockTransferData instance,
) => <String, dynamic>{'event_id': instance.eventId, 'status': instance.status};
