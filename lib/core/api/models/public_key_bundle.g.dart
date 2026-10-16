// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_key_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicKeyBundle _$PublicKeyBundleFromJson(Map<String, dynamic> json) =>
    PublicKeyBundle(
      activeKeyId: (json['active_key_id'] as num?)?.toInt(),
      keys: (json['keys'] as List<dynamic>)
          .map((e) => PublicKey.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublicKeyBundleToJson(PublicKeyBundle instance) =>
    <String, dynamic>{
      'active_key_id': instance.activeKeyId,
      'keys': instance.keys,
    };
