import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../config/app_config.dart';
import '../offline/offline_queue.dart';
import 'push_service.dart';
import 'push_status.dart';
import 'push_token_notifier.dart';

// Se reexporta [PushTokenNotifier] con `pushTokenProvider` (movidos a su propio
// archivo por SRP) para no romper a quienes importan `push/push_controller.dart`.
export 'push_token_notifier.dart';

/// Instancia del plumbing de push. Se expone para poder sustituirla en tests.
final pushServiceProvider = Provider<PushService>((ref) => PushService());

/// ¿Están las credenciales de Firebase en `config/*.json`? Sin ellas el push no
/// arranca (la app funciona igual). Se expone para sustituirlo en tests.
final pushConfiguredProvider = Provider<bool>(
  (ref) => AppConfig.isFirebaseConfigured,
);

/// Coordina el registro push (FCM) y publica el [PushStatus] que observa la UI.
///
/// `build()` arranca el init (Firebase + notificaciones locales + listeners) y,
/// si el permiso ya estaba concedido, obtiene el token sin volver a preguntar.
/// El registro completo (pedir permiso + token) lo dispara [register] desde el
/// botón "Activar notificaciones".
class PushController extends Notifier<PushStatus> {
  late final PushService _service;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _ready = false;

  /// Topics FCM a los que está suscrito este dispositivo (rol y tienda).
  final Set<String> _topics = {};

  /// Payloads de notificaciones tocadas. El coordinador escucha este stream y
  /// navega a '/notifications' (el gancho se cablea en app.dart).
  Stream<String> get taps => _taps.stream;

  static const PushStatus _notConfigured = PushStatus(
    state: PushRegistrationState.unavailable,
    message: 'Las notificaciones push todavía no están configuradas.',
  );

  @override
  PushStatus build() {
    _service = ref.read(pushServiceProvider);
    ref.onDispose(_taps.close);
    // Suelta los listeners de FCM si el provider se destruye (cierre del
    // contenedor): no quedan suscripciones vivas apuntando a este notifier.
    ref.onDispose(() {
      try {
        unawaited(_service.cancelSubscriptions().catchError((Object _) {}));
      } on Object {
        // Best-effort: el cierre del contenedor nunca debe fallar por el push.
      }
    });
    if (!ref.read(pushConfiguredProvider)) return _notConfigured;
    // Topics por rol/tienda: se ajustan al iniciar y cerrar sesión.
    ref.listen<Session?>(sessionProvider, (_, next) {
      if (_ready) unawaited(_syncTopics(next));
    });
    unawaited(_bootstrap());
    return const PushStatus.idle();
  }

  Future<void> _bootstrap() async {
    // El arranque del push nunca debe tumbar la app: la plataforma puede lanzar
    // Error (no solo Exception) en tests, en iOS sin APNs, etc.
    try {
      _ready = await _initialize();
      if (!_ready) {
        state = _notConfigured;
        return;
      }
      // Con el permiso ya concedido se re-registra sin preguntar: FCM vuelve a
      // entregar el identificador por onRegistered.
      if (await _service.hasPermission()) {
        await _service.registerDevice();
      }
      await _syncTopics(ref.read(sessionProvider));
    } on Object catch (e) {
      state = PushStatus(
        state: PushRegistrationState.failed,
        message: 'No se pudo iniciar el push: $e',
      );
    }
  }

  /// Topics de difusión que publica el backend: `role_<rol>` (p. ej.
  /// `role_chofer`) y, si el usuario tiene tienda, `node_<id>`. Sin sesión se
  /// desuscribe de todo. Falla en silencio: el push nunca tumba la app.
  Future<void> _syncTopics(Session? session) async {
    final wanted = <String>{
      if (session != null) 'role_${session.role.backendKey}',
      if (session?.storeNode != null) 'node_${session!.storeNode!.id}',
    };
    try {
      for (final topic in _topics.difference(wanted)) {
        await _service.unsubscribeFromTopic(topic);
      }
      for (final topic in wanted.difference(_topics)) {
        await _service.subscribeToTopic(topic);
      }
      _topics
        ..clear()
        ..addAll(wanted);
    } on Object {
      // Sin red o sin Google Play: se reintenta en el próximo cambio/arranque.
    }
  }

  /// Flujo lanzado por el usuario: pide permiso y obtiene el token.
  Future<void> register() async {
    if (!ref.read(pushConfiguredProvider)) {
      state = _notConfigured;
      return;
    }
    state = state.copyWith(
      state: PushRegistrationState.registering,
      message: null,
    );
    try {
      if (!_ready) {
        _ready = await _initialize();
        if (!_ready) {
          state = _notConfigured;
          return;
        }
      }
      if (!await _service.requestPermission()) {
        state = const PushStatus(
          state: PushRegistrationState.failed,
          message:
              'Permiso de notificaciones denegado. Actívalo en los ajustes '
              'del teléfono.',
        );
        return;
      }
      // El identificador llega luego por onRegistered → [_onToken].
      await _service.registerDevice();
    } on Object catch (e) {
      state = PushStatus(
        state: PushRegistrationState.failed,
        message: 'No se pudo activar el push: $e',
      );
    }
  }

  Future<bool> _initialize() => _service.initialize(
    onToken: _onToken,
    onTap: _onTap,
    onUnregistered: _onUnregistered,
  );

  /// FCM dio de baja este dispositivo: se olvida el identificador.
  void _onUnregistered() {
    unawaited(ref.read(pushTokenProvider.notifier).clear());
    state = const PushStatus.idle();
  }

  /// Baja del push en este dispositivo: invalida el token y lo olvida (y avisa
  /// al backend con `push_token: null`).
  Future<void> unregister() async {
    await _service.unregister();
    await ref.read(pushTokenProvider.notifier).clear();
    _syncTokenWithBackend(null);
    state = const PushStatus.idle();
  }

  /// Token nuevo o rotado. Se guarda (viaja como `device.push_token` en el
  /// próximo login) y, si hay sesión, se actualiza ya en el backend
  /// (`PUT /app/devices/current/push-token`), encolado offline.
  void _onToken(String token) {
    final previous = ref.read(pushTokenProvider);
    unawaited(ref.read(pushTokenProvider.notifier).save(token));
    if (previous != token) _syncTokenWithBackend(token);
    state = state.copyWith(
      state: PushRegistrationState.registered,
      token: token,
      message: null,
    );
  }

  /// Solo con sesión real (Bearer): sin sesión el token viaja en el login.
  void _syncTokenWithBackend(String? token) {
    if (ref.read(sessionProvider)?.token == null) return;
    unawaited(
      ref
          .read(offlineQueueProvider)
          .submit(
            kind: 'updateDevicePushToken',
            payload: {'push_token': token},
            label: 'Notificaciones push',
          )
          .catchError((Object _) => SubmitOutcome.failed),
    );
  }

  void _onTap(String? payload) {
    // Se emite siempre (payload puede ser null): el coordinador navega a la
    // bandeja. Un payload no vacío permitiría abrir el detalle directo.
    _taps.add(payload ?? '');
  }
}

/// Provider a cablear en app.dart. Observarlo arranca el init/registro push y
/// expone el [PushStatus] para la UI.
final pushRegistrationProvider = NotifierProvider<PushController, PushStatus>(
  PushController.new,
);

/// Stream de taps de notificación. El coordinador lo escucha para navegar a
/// '/notifications'.
final pushTapProvider = StreamProvider<String>(
  (ref) => ref.watch(pushRegistrationProvider.notifier).taps,
);
