// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dispatch_destination_type.dart';

part 'dispatch_destination.g.dart';

@JsonSerializable()
class DispatchDestination {
  const DispatchDestination({
    required this.type,
    required this.name,
    required this.address,
  });

  factory DispatchDestination.fromJson(Map<String, Object?> json) =>
      _$DispatchDestinationFromJson(json);

  final DispatchDestinationType? type;
  final String? name;

  /// Dirección (solo en home)
  final String? address;

  Map<String, Object?> toJson() => _$DispatchDestinationToJson(this);
}
