// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispatch_destination.dart';

part 'destinations.g.dart';

@JsonSerializable()
class Destinations {
  const Destinations({
    required this.shipmentReference,
    required this.destination,
    required this.lineCount,
  });

  factory Destinations.fromJson(Map<String, Object?> json) =>
      _$DestinationsFromJson(json);

  @JsonKey(name: 'shipment_reference')
  final String? shipmentReference;
  final DispatchDestination destination;
  @JsonKey(name: 'line_count')
  final int lineCount;

  Map<String, Object?> toJson() => _$DestinationsToJson(this);
}
