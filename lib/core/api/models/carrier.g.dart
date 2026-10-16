// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Carrier _$CarrierFromJson(Map<String, dynamic> json) => Carrier(
  id: json['id'] as String,
  name: json['name'] as String,
  taxId: json['tax_id'] as String,
  status: CarrierStatus.fromJson(json['status'] as String),
  ratingCount: (json['rating_count'] as num).toInt(),
  documents: (json['documents'] as List<dynamic>)
      .map((e) => CarrierDocument.fromJson(e as Map<String, dynamic>))
      .toList(),
  averageRating: (json['average_rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CarrierToJson(Carrier instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'tax_id': instance.taxId,
  'status': instance.status,
  'average_rating': instance.averageRating,
  'rating_count': instance.ratingCount,
  'documents': instance.documents,
};
