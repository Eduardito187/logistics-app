// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_change_promotion_rules_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceChangePromotionRulesRequest
_$CommerceChangePromotionRulesRequestFromJson(Map<String, dynamic> json) =>
    CommerceChangePromotionRulesRequest(
      type: CommerceChangePromotionRulesRequestType.fromJson(
        json['type'] as String,
      ),
      value: (json['value'] as num).toInt(),
      minSubtotalCents: (json['min_subtotal_cents'] as num?)?.toInt(),
      channel: json['channel'] == null
          ? null
          : PromotionChannel.fromJson(json['channel'] as String),
      startsAt: json['starts_at'] as String?,
      endsAt: json['ends_at'] as String?,
    );

Map<String, dynamic> _$CommerceChangePromotionRulesRequestToJson(
  CommerceChangePromotionRulesRequest instance,
) => <String, dynamic>{
  'type': instance.type,
  'value': instance.value,
  'min_subtotal_cents': instance.minSubtotalCents,
  'channel': instance.channel,
  'starts_at': instance.startsAt,
  'ends_at': instance.endsAt,
};
