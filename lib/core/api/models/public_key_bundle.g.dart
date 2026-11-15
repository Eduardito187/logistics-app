// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_key_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicKeyBundle _$PublicKeyBundleFromJson(Map<String, dynamic> json) =>
    PublicKeyBundle(
      open: json['open'] as bool,
      activeKeyId: (json['active_key_id'] as num?)?.toInt(),
      keys: (json['keys'] as List<dynamic>)
          .map((e) => PublicKey.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublicKeyBundleToJson(PublicKeyBundle instance) =>
    <String, dynamic>{
      'open': instance.open,
      'active_key_id': instance.activeKeyId,
      'keys': instance.keys,
    };
