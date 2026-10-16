/// Resultado de un envío: se ejecutó en línea, o quedó encolado para reintento.
///
/// Lo devuelve [OfflineQueue.submit]. La presentación debe traducirlo a un
/// aviso con `showSubmitOutcome` (core/offline/submit_feedback.dart) en vez de
/// reimplementar el mapeo mensaje/color en cada feature.
enum SubmitOutcome { sent, queued, failed }
