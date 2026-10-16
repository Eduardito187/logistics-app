import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Normaliza una fecha a solo año/mes/día (sin hora) para los filtros del día.
DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Fecha seleccionada para los planes del día. Arranca en hoy.
class PlansDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _dateOnly(DateTime.now());

  void select(DateTime date) => state = _dateOnly(date);
}

final plansDateProvider = NotifierProvider<PlansDateNotifier, DateTime>(
  PlansDateNotifier.new,
);
