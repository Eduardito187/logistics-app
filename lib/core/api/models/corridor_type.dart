// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum CorridorType {
  @JsonValue('cd_to_customer')
  cdToCustomer('cd_to_customer'),
  @JsonValue('cd_to_cd')
  cdToCd('cd_to_cd'),
  @JsonValue('cd_to_store')
  cdToStore('cd_to_store'),
  @JsonValue('store_to_store')
  storeToStore('store_to_store'),
  @JsonValue('store_to_cd')
  storeToCd('store_to_cd'),
  @JsonValue('store_pickup')
  storePickup('store_pickup'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CorridorType(this.json);

  factory CorridorType.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError(
        'Cannot convert enum value with null JSON representation to String. '
        'This usually happens for \$unknown or @JsonValue(null) entries.',
      );
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<CorridorType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
