// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconciliation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reconciliation _$ReconciliationFromJson(Map<String, dynamic> json) =>
    Reconciliation(
      notes: json['notes'] as String?,
      photoPath: json['photo_path'] as String?,
      missing: (json['missing'] as List<dynamic>?)
          ?.map((e) => Missing2.fromJson(e as Map<String, dynamic>))
          .toList(),
      surplus: (json['surplus'] as List<dynamic>?)
          ?.map((e) => Surplus2.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReconciliationToJson(Reconciliation instance) =>
    <String, dynamic>{
      'notes': instance.notes,
      'photo_path': instance.photoPath,
      'missing': instance.missing,
      'surplus': instance.surplus,
    };
