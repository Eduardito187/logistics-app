import 'dart:math' as math;

import '../network/api_exception.dart';

/// Política de reintentos y retención de las colas offline (acciones y fotos).
///
/// Clasificación de errores al subir una fila:
/// - **Transitorio** (no es culpa del dato): sin conexión, 429, 5xx y 401. La
///   fila queda `pending`. El 401 es transitorio para la COLA: el token se
///   revocó o expiró, la sesión se cierra y la fila se sube con la próxima
///   sesión; marcarla `failed` perdería escrituras de terreno.
/// - **Permanente**: el resto de 4xx (400, 403, 404, 409, 422...). Reintentar
///   no lo arregla: pasa a `failed` y se reporta.
///
/// Solo 429/5xx suman a `attempts` (el servidor respondió y no pudo): estar
/// días sin señal NO agota la fila. Al llegar a [maxServerAttempts] la fila
/// pasa a `failed` (`retries_exhausted`) para no martillar un endpoint roto.
abstract final class SyncRetryPolicy {
  /// Tope de respuestas 429/5xx por fila antes de darla por perdida. Con el
  /// drenado periódico cada 15 min, ~50 intentos son varias horas de backend
  /// caído sin perder nada; más allá conviene que lo vea soporte.
  static const int maxServerAttempts = 50;

  /// Las filas `failed` (ya reportadas) se purgan pasado este plazo.
  static const Duration failedRetention = Duration(days: 7);

  /// Posiciones GPS del camión aún pendientes: pasado este plazo se descartan
  /// (con días sin señal se acumulan ~360/h y ya no sirven para seguimiento).
  /// Solo aplica a `ingestTruckPosition`; ninguna otra pendiente se descarta.
  static const Duration truckPositionRetention = Duration(days: 7);

  /// Primer escalón del backoff y techo.
  static const Duration backoffBase = Duration(seconds: 5);
  static const Duration backoffMax = Duration(minutes: 10);

  /// `true` si conviene dejar la fila pendiente y reintentar luego.
  static bool isTransient(ApiException e) =>
      e.isConnectionError ||
      e.isRateLimited ||
      e.isServerError ||
      e.isUnauthorized ||
      // status 0 sin respuesta (p. ej. cancelada): tampoco es culpa del dato.
      e.status == 0;

  /// `true` si el error suma a `attempts` (el servidor respondió 429/5xx).
  static bool countsAsAttempt(ApiException e) =>
      e.isRateLimited || e.isServerError;

  /// Espera antes del próximo reintento en primer plano: exponencial sobre
  /// [attempts] (5 s, 10 s, 20 s... hasta [backoffMax]).
  static Duration backoffFor(int attempts) {
    final exp = math.min(math.max(attempts, 0), 16);
    final ms = backoffBase.inMilliseconds * (1 << exp);
    return Duration(milliseconds: math.min(ms, backoffMax.inMilliseconds));
  }
}
