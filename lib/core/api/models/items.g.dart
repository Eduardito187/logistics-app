// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Items _$ItemsFromJson(Map<String, dynamic> json) =>
    Items(name: json['name'] as String, qty: (json['qty'] as num).toInt());

Map<String, dynamic> _$ItemsToJson(Items instance) => <String, dynamic>{
  'name': instance.name,
  'qty': instance.qty,
};
