import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Reintentos máximos de un provider que falló (ver [appProviderRetry]).
const int kProviderMaxRetries = 3;

/// Primer escalón del backoff de [appProviderRetry] (400 ms, 800 ms, 1,6 s).
const Duration kProviderRetryBaseDelay = Duration(milliseconds: 400);

/// Política de reintento automático de providers para el `ProviderContainer`
/// de la app (`ProviderContainer(retry: appProviderRetry)`).
///
/// El default de Riverpod 3 reintenta 10 veces (~38 s) CUALQUIER excepción,
/// incluso un 403/404/422 que nunca va a cambiar (p. ej. "sin asignación"):
/// requests inútiles compitiendo con la UI. Acá solo se reintenta lo
/// transitorio — sin conexión/timeout, 5xx y 429 — como mucho
/// [kProviderMaxRetries] veces con backoff `400 ms · 2^n`. Todo lo demás
/// (4xx, errores de programación, fallas de dependencias que ya reintentan por
/// su cuenta) devuelve `null`: sin reintento.
Duration? appProviderRetry(int retryCount, Object error) {
  if (retryCount >= kProviderMaxRetries) return null;
  final api = switch (error) {
    ApiException() => error,
    DioException() => ApiException.fromDio(error),
    _ => null,
  };
  if (api == null || !_isTransient(api)) return null;
  return kProviderRetryBaseDelay * (1 << retryCount);
}

bool _isTransient(ApiException e) =>
    e.isConnectionError || e.isServerError || e.isRateLimited;
