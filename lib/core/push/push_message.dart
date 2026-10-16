/// Contenido ya normalizado de un mensaje push entrante (ntfy/UnifiedPush).
///
/// ntfy entrega el cuerpo como bytes; puede venir en JSON (`{title, message,
/// ...}`) o como texto plano. Esta clase deja listo lo que la notificación
/// local necesita mostrar y el `payload` para navegar al tocarla. La arma
/// `PushService.decodeMessage` (push/push_service.dart).
class PushMessage {
  const PushMessage({required this.title, required this.body, this.payload});

  final String title;
  final String body;

  /// Dato opaco que viaja con la notificación local (p. ej. id de envío o de
  /// notificación). Se devuelve en el tap para que la UI navegue.
  final String? payload;
}
