import '../../../../core/api/models/shipment.dart';

/// Una página de envíos del nodo más la pista de si queda otra.
///
/// La lista de tienda es la única del feature que puede pasar de 50 filas
/// (bandeja de una tienda grande), así que se pagina de verdad en vez de
/// quedarse con la primera página del cliente generado.
class ShipmentPage {
  const ShipmentPage({required this.shipments, required this.hasMore});

  /// Página vacía y sin continuación (p. ej. se pidió una página que ya no
  /// existe tras un refresco).
  static const ShipmentPage empty = ShipmentPage(
    shipments: <Shipment>[],
    hasMore: false,
  );

  /// Envíos de ESTA página (no el acumulado).
  final List<Shipment> shipments;

  /// `true` si el servidor tiene más envíos después de esta página.
  final bool hasMore;
}
