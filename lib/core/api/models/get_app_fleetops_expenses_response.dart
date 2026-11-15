// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expense.dart';
import 'list_meta.dart';

part 'get_app_fleetops_expenses_response.g.dart';

@JsonSerializable()
class GetAppFleetopsExpensesResponse {
  const GetAppFleetopsExpensesResponse({required this.data, this.meta});

  factory GetAppFleetopsExpensesResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetopsExpensesResponseFromJson(json);

  final List<Expense> data;
  final ListMeta? meta;

  Map<String, Object?> toJson() => _$GetAppFleetopsExpensesResponseToJson(this);
}
