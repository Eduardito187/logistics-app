// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_promotion_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommercePromotionView _$CommercePromotionViewFromJson(
  Map<String, dynamic> json,
) => CommercePromotionView(
  id: json['id'] as String,
  name: json['name'] as String,
  type: CommercePromotionViewType.fromJson(json['type'] as String),
  value: (json['value'] as num).toInt(),
  currency: json['currency'] as String,
  status: CommercePromotionViewStatus.fromJson(json['status'] as String),
  version: (json['version'] as num).toInt(),
  isCoupon: json['is_coupon'] as bool,
  freeShipping: json['free_shipping'] as bool,
  code: json['code'] as String?,
  conditions: json['conditions'] == null
      ? null
      : CommercePromotionConditions.fromJson(
          json['conditions'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$CommercePromotionViewToJson(
  CommercePromotionView instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'type': instance.type,
  'value': instance.value,
  'currency': instance.currency,
  'conditions': instance.conditions,
  'status': instance.status,
  'version': instance.version,
  'is_coupon': instance.isCoupon,
  'free_shipping': instance.freeShipping,
};
