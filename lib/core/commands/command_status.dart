/// Cómo respondió el backend al ejecutar un comando de escritura.
///
/// - [applied]: la escritura se aplicó de inmediato (respuesta directa /
///   síncrona). El cambio ya quedó hecho.
/// - [accepted]: el backend aceptó la orden pero la procesa de forma
///   asíncrona (HTTP 202 / `AcceptedEnvelope`). Todavía NO está aplicada; el
///   estado real recién se verá cuando el backend termine de procesarla.
enum CommandStatus { applied, accepted }
