import 'print_result_message.dart';

/// Estado de la impresión de prueba: si está imprimiendo y el resultado veraz
/// de la última prueba (lo muestran la tarjeta de impresora y el asistente).
class PrintTestState {
  const PrintTestState({this.printing = false, this.lastResult});

  final bool printing;
  final PrintResultMessage? lastResult;
}
