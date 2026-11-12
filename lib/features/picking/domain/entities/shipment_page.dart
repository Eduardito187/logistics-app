import 'package:flutter/foundation.dart';

import '../../../../core/api/models/shipment.dart';

/// Una página de pedidos y si puede haber más.
///
/// Se pagina por NÚMERO DE PÁGINA (no por cursor) a propósito: el `meta` del
/// cliente generado es ilegible hoy —deserializa `perPage`/`nextCursor` en
/// camelCase mientras el backend manda `per_page`/`next_page`—, así que el
/// cursor siempre vendría vacío y el scroll no avanzaría nunca. Con el número
/// de página lo controla la app y no depende de ese `meta`.
///
/// [hasMore] sale del `meta` cuando SÍ se puede leer y, si no, de la heurística
/// "página completa ⇒ puede haber más" (cuesta a lo sumo un GET que vuelve
/// vacío al final). Cuando se arregle el generador, el `meta` manda solo.
@immutable
class ShipmentPage {
  const ShipmentPage({required this.items, required this.hasMore});

  final List<Shipment> items;

  /// Puede haber más páginas después de esta.
  final bool hasMore;
}
