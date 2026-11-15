// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_drop_missing_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreDropMissingUnit _$StoreDropMissingUnitFromJson(
  Map<String, dynamic> json,
) => StoreDropMissingUnit(
  unitId: json['unit_id'] as String,
  reason: MissingUnitReason.fromJson(json['reason'] as String),
);

Map<String, dynamic> _$StoreDropMissingUnitToJson(
  StoreDropMissingUnit instance,
) => <String, dynamic>{'unit_id': instance.unitId, 'reason': instance.reason};
