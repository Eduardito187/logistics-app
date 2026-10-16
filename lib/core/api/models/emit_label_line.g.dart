// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emit_label_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmitLabelLine _$EmitLabelLineFromJson(Map<String, dynamic> json) =>
    EmitLabelLine(
      sku: json['sku'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      piecesPerUnit: (json['pieces_per_unit'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$EmitLabelLineToJson(EmitLabelLine instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'name': instance.name,
      'quantity': instance.quantity,
      'pieces_per_unit': instance.piecesPerUnit,
    };
