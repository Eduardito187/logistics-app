import 'package:flutter/foundation.dart';

import 'home_widget_kind.dart';
import 'home_widget_state.dart';

/// Contenido de UN widget de la pantalla de inicio, tal como viaja al canal
/// nativo en "update" (`{"kind", "payload"}`).
///
/// Todo payload lleva `state`, `updatedAt` (epoch ms, lo pone el controller al
/// enviar) y `route` (ruta go_router que abre la app al tocar el widget). Cada
/// kind agrega sus [fields].
@immutable
abstract class HomeWidgetPayload {
  const HomeWidgetPayload();

  HomeWidgetKind get kind;

  HomeWidgetState get state;

  /// Ruta go_router que se abre al tocar el widget.
  String get route;

  /// Campos propios del kind (sin `state`, `updatedAt` ni `route`).
  Map<String, Object?> get fields;

  /// Cambio que se publica al instante, sin esperar el intervalo mínimo:
  /// otro tipo de payload (p. ej. del "cargando" a los datos), otro estado u
  /// otra ruta. Los kinds con "parada" agregan el cambio de parada.
  bool isMajorChangeFrom(HomeWidgetPayload previous) =>
      previous.runtimeType != runtimeType ||
      previous.state != state ||
      previous.route != route;

  /// `true` si el widget se vería IGUAL (ignora `updatedAt`): no se reenvía.
  bool sameContentAs(HomeWidgetPayload other) =>
      other.kind == kind &&
      other.runtimeType == runtimeType &&
      other.state == state &&
      other.route == route &&
      mapEquals(other.fields, fields);

  /// Argumento `payload` del método "update" del canal.
  Map<String, Object?> toMap({required DateTime updatedAt}) => {
    'state': state.wireName,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'route': route,
    ...fields,
  };
}
