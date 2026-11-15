// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_printer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkPrinter _$NetworkPrinterFromJson(Map<String, dynamic> json) =>
    NetworkPrinter(
      id: json['id'] as String,
      name: json['name'] as String,
      model: json['model'] as String?,
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      language: NetworkPrinterLanguage.fromJson(json['language'] as String),
      nodeId: json['node_id'] as String?,
      nodeName: json['node_name'] as String?,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$NetworkPrinterToJson(NetworkPrinter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'model': instance.model,
      'host': instance.host,
      'port': instance.port,
      'language': instance.language,
      'node_id': instance.nodeId,
      'node_name': instance.nodeName,
      'location': instance.location,
    };
