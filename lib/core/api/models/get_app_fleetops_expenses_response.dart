// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expense.dart';

part 'get_app_fleetops_expenses_response.g.dart';

@JsonSerializable()
class GetAppFleetopsExpensesResponse {
  const GetAppFleetopsExpensesResponse({required this.data});

  factory GetAppFleetopsExpensesResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetopsExpensesResponseFromJson(json);

  final List<Expense> data;

  Map<String, Object?> toJson() => _$GetAppFleetopsExpensesResponseToJson(this);
}
