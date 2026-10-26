import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Si se muestran solo las alertas sin reconocer (true) o todas (false).
class AlertsFilterNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setUnacknowledgedOnly({required bool value}) => state = value;
}

/// Sin autoDispose a propósito: es un solo `bool` y conserva el filtro elegido
/// al volver a la pantalla de alertas durante la sesión.
final alertsFilterProvider = NotifierProvider<AlertsFilterNotifier, bool>(
  AlertsFilterNotifier.new,
);
