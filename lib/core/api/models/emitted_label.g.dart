// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emitted_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmittedLabel _$EmittedLabelFromJson(Map<String, dynamic> json) => EmittedLabel(
  orderNumber: json['order_number'] as String,
  labelId: json['label_id'] as String,
  keyId: (json['key_id'] as num).toInt(),
  sku: json['sku'] as String,
  lineNumber: (json['line_number'] as num).toInt(),
  qrContent: json['qr_content'] as String,
  zpl: json['zpl'] as String,
  emittedAt: (json['emitted_at'] as num).toInt(),
  revoked: json['revoked'] as bool,
  revokedAt: (json['revoked_at'] as num?)?.toInt(),
  revokedReason: json['revoked_reason'] as String?,
);

Map<String, dynamic> _$EmittedLabelToJson(EmittedLabel instance) =>
    <String, dynamic>{
      'order_number': instance.orderNumber,
      'label_id': instance.labelId,
      'key_id': instance.keyId,
      'sku': instance.sku,
      'line_number': instance.lineNumber,
      'qr_content': instance.qrContent,
      'zpl': instance.zpl,
      'emitted_at': instance.emittedAt,
      'revoked': instance.revoked,
      'revoked_at': instance.revokedAt,
      'revoked_reason': instance.revokedReason,
    };
