import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session.dart';

/// Renueva el token ANTES de que venza, sin que el usuario se entere.
///
/// Problema que resuelve: el token del dispositivo vence y, hasta ahora, el
/// único que llamaba a `refreshToken()` era un botón de ajustes. A un chofer
/// con la app abierta todo el día se le caía la sesión en medio de una entrega
/// (401 → login) justo cuando menos puede resolverlo.
///
/// Cuándo renueva:
/// - **Por tiempo**: un timer apunta a [refreshMargin] antes de
///   `Session.tokenExpiresAt`.
/// - **Al volver a primer plano**: los timers de Dart no corren con el teléfono
///   suspendido (la app pasa horas en el bolsillo), así que al `resumed` se
///   revisa si ya toca y se renueva en el acto.
/// - **Sin `expires_at`**: si el backend (o el login) no informó el
///   vencimiento, se cae a una política por antigüedad del token
///   ([unknownExpiryMaxAge]); la primera renovación ya trae el vencimiento
///   real y de ahí en adelante se usa ese.
///
/// Nunca molesta ni cierra sesión: si la renovación falla (sin señal, 5xx) se
/// reintenta con una espera creciente y el token viejo sigue vigente; si el
/// backend lo rechaza, el camino normal del 401 hace su trabajo.
///
/// El estado es el momento para el que está programada la próxima renovación
/// (`null` sin sesión real): sirve para depurar y para los tests.
class TokenRefreshNotifier extends Notifier<DateTime?> {
  /// Cuánto antes del vencimiento se renueva.
  static const Duration refreshMargin = Duration(minutes: 10);

  /// Antigüedad a la que se renueva cuando NO se conoce el vencimiento.
  /// Conservador: los tokens de la app duran bastante más que esto.
  static const Duration unknownExpiryMaxAge = Duration(hours: 12);

  /// Primera espera tras una renovación fallida, y su techo (duplica cada vez).
  static const Duration failureRetryBase = Duration(minutes: 2);
  static const Duration failureRetryMax = Duration(minutes: 30);

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  int _failures = 0;

  @override
  DateTime? build() {
    // Solo interesa la identidad del token y sus fechas: cambios de abilities o
    // de tienda no reprograman nada.
    final token = ref.watch(sessionProvider.select((s) => s?.token));
    final expiresAt = ref.watch(
      sessionProvider.select((s) => s?.tokenExpiresAt),
    );
    final issuedAt = ref.watch(sessionProvider.select((s) => s?.tokenIssuedAt));

    _timer?.cancel();
    _timer = null;
    _failures = 0;
    try {
      _lifecycle = AppLifecycleListener(onResume: refreshIfDue);
    } on Object {
      // Sin WidgetsBinding (tests unitarios puros): solo timer.
      _lifecycle = null;
    }
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _lifecycle?.dispose();
    });

    // Sesión dev (token null) o sin sesión: nada que renovar.
    if (token == null) return null;

    final due = dueAt(
      expiresAt: expiresAt,
      issuedAt: issuedAt,
      now: DateTime.now(),
    );
    _armTimer(due);
    return due;
  }

  /// Momento en que corresponde renovar, dadas las fechas del token. Nunca
  /// devuelve un instante anterior a [now] (si ya se pasó, es "ahora").
  static DateTime dueAt({
    required DateTime? expiresAt,
    required DateTime? issuedAt,
    required DateTime now,
  }) {
    final DateTime target;
    if (expiresAt != null) {
      target = expiresAt.subtract(refreshMargin);
    } else {
      // Sin vencimiento conocido: por antigüedad del token. Sin fecha de
      // emisión (copia vieja de la sesión) se cuenta desde ahora.
      target = (issuedAt ?? now).add(unknownExpiryMaxAge);
    }
    return target.isBefore(now) ? now : target;
  }

  void _armTimer(DateTime due) {
    final delay = due.difference(DateTime.now());
    _timer?.cancel();
    _timer = Timer(delay > Duration.zero ? delay : Duration.zero, () {
      _timer = null;
      unawaited(_refreshQuietly());
    });
  }

  /// Renueva YA si el token está dentro del margen (lo llama el regreso a
  /// primer plano). Si todavía falta, no toca la red.
  void refreshIfDue() {
    if (!ref.mounted) return;
    final due = state;
    if (due == null) return;
    if (DateTime.now().isBefore(due)) return;
    unawaited(_refreshQuietly());
  }

  /// Renovación en segundo plano: nunca lanza y nunca cierra la sesión.
  ///
  /// `SessionNotifier.refreshToken()` ya deduplica las renovaciones en vuelo,
  /// así que el timer y el regreso a primer plano no pueden emitir dos tokens.
  Future<void> _refreshQuietly() async {
    if (!ref.mounted) return;
    final session = ref.read(sessionProvider);
    if (session?.token == null) return;
    try {
      await ref.read(sessionProvider.notifier).refreshToken();
      // Con éxito, el cambio de token reconstruye este notifier (watch) y
      // reprograma el timer con el vencimiento nuevo.
    } on Object {
      if (!ref.mounted) return;
      // Falla transitoria (sin señal, 5xx) o rechazo: el token viejo sigue
      // vigente y el usuario no se enteró. Se reintenta más tarde con espera
      // creciente; un 401 real lo resuelve el interceptor de Dio.
      _failures++;
      final backoff = failureRetryBase * (1 << (_failures - 1).clamp(0, 4));
      final delay = backoff > failureRetryMax ? failureRetryMax : backoff;
      final retryAt = DateTime.now().add(delay);
      state = retryAt;
      _armTimer(retryAt);
    }
  }
}

/// Mantiene vivo el refresh proactivo del token. Se escucha una sola vez
/// (desde `routerProvider`, que vive todo el arranque).
final tokenRefreshProvider = NotifierProvider<TokenRefreshNotifier, DateTime?>(
  TokenRefreshNotifier.new,
);

/// Fuerza la renovación en los tests sin esperar el timer real.
@visibleForTesting
Future<void> refreshTokenQuietlyForTest(TokenRefreshNotifier notifier) =>
    notifier._refreshQuietly();

/// `true` si hay un timer de renovación armado (tests).
@visibleForTesting
bool tokenRefreshHasTimer(TokenRefreshNotifier notifier) =>
    notifier._timer?.isActive ?? false;
