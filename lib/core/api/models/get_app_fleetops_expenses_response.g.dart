// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_expenses_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsExpensesResponse _$GetAppFleetopsExpensesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetopsExpensesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => Expense.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppFleetopsExpensesResponseToJson(
  GetAppFleetopsExpensesResponse instance,
) => <String, dynamic>{'data': instance.data};
