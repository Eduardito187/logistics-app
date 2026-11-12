import 'ipp_endpoint.dart';
import 'ipp_printer_info.dart';

/// Impresora IPP ya ubicada: la ruta que respondió, lo que informó de sí
/// misma y la cabecera `Authorization` que funcionó (para no mandar el
/// documento dos veces si hay que autenticarse).
class IppConnection {
  const IppConnection({
    required this.endpoint,
    required this.info,
    this.authorization,
  });

  final IppEndpoint endpoint;
  final IppPrinterInfo info;
  final String? authorization;

  /// `true` si para hablarle hubo que autenticarse.
  bool get authenticated => authorization != null;
}
