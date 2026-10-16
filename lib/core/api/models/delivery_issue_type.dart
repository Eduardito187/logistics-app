// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Type of in-progress delivery issue reported by the driver.
@JsonEnum()
enum DeliveryIssueType {
  @JsonValue('DELAY')
  delay('DELAY'),
  @JsonValue('ACCESS')
  access('ACCESS'),
  @JsonValue('CUSTOMER_REQUEST')
  customerRequest('CUSTOMER_REQUEST'),
  @JsonValue('ADDRESS_UNCLEAR')
  addressUnclear('ADDRESS_UNCLEAR'),
  @JsonValue('OTHER')
  other('OTHER'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const DeliveryIssueType(this.json);

  factory DeliveryIssueType.fromJson(String json) =>
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
  static List<DeliveryIssueType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
