// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicKey _$PublicKeyFromJson(Map<String, dynamic> json) => PublicKey(
  id: (json['id'] as num).toInt(),
  publicKey: json['public_key'] as String,
);

Map<String, dynamic> _$PublicKeyToJson(PublicKey instance) => <String, dynamic>{
  'id': instance.id,
  'public_key': instance.publicKey,
};
