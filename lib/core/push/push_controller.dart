import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_endpoint_notifier.dart';
import 'push_service.dart';
import 'push_status.dart';

// Se reexporta [PushEndpointNotifier] con `pushEndpointProvider` (movidos a su
// propio archivo por SRP) para no romper a quienes importan
// `push/push_controller.dart`.
export 'push_endpoint_notifier.dart';

/// Instancia del plumbing de push. Se expone para poder sustituirla en tests.
final pushServiceProvider = Provider<PushService>((ref) => PushService());

/// Coordina el registro push y publica el [PushStatus] que observa la UI.
///
/// `build()` arranca el init (callbacks de UnifiedPush + notificaciones
/// locales) y, si ya había un distribuidor elegido, refleja el estado y
/// reintenta el registro para refrescar el endpoint. El registro completo
/// (permiso + elección de distribuidor) lo dispara [register] desde el botón
/// "Activar notificaciones".
class PushController extends Notifier<PushStatus> {
  late final PushService _service;
  final StreamController<String> _taps = StreamController<String>.broadcast();

  /// Payloads de notificaciones tocadas. El coordinador escucha este stream y
  /// navega a '/notifications'. (No se puede editar el router acá: el gancho se
  /// cablea en app.dart observando [pushTapProvider].)
  Stream<String> get taps => _taps.stream;

  @override
  PushStatus build() {
    _service = ref.read(pushServiceProvider);
    ref.onDispose(_taps.close);
    unawaited(_bootstrap());
    return const PushStatus.idle();
  }

  Future<void> _bootstrap() async {
    // El arranque del push nunca debe tumbar la app: la plataforma puede lanzar
    // Error (no solo Exception) en entornos sin distribuidor, en tests o en iOS.
    try {
      await _service.initialize(
        onNewEndpoint: _onNewEndpoint,
        onRegistrationFailed: _onRegistrationFailed,
        onUnregistered: _onUnregistered,
        onMessage: _onMessage,
        onTap: _onTap,
      );

      // Si ya hay distribuidor elegido, se refleja y se reintenta el registro
      // para obtener un endpoint fresco sin volver a pedir permiso.
      final String? distributor = await _service.savedDistributor();
      final String? endpoint = ref.read(pushEndpointProvider);
      if (distributor != null) {
        state = state.copyWith(
          state: endpoint != null
              ? PushRegistrationState.registered
              : PushRegistrationState.registering,
          distributor: distributor,
          endpoint: endpoint,
        );
        await _service.register();
      }
    } on Object catch (e) {
      state = PushStatus(
        state: PushRegistrationState.failed,
        message: 'No se pudo iniciar el push: $e',
      );
    }
  }

  /// Flujo completo lanzado por el usuario: pide permiso, elige distribuidor y
  /// solicita el endpoint. El endpoint llega luego por [_onNewEndpoint].
  Future<void> register() async {
    state = state.copyWith(state: PushRegistrationState.registering);

    await _service.requestNotificationPermission();

    String? distributor = await _service.savedDistributor();
    if (distributor == null) {
      final List<String> distributors = await _service.availableDistributors();
      if (distributors.isEmpty) {
        state = const PushStatus(
          state: PushRegistrationState.unavailable,
          message:
              'No hay una app de notificaciones (distribuidor UnifiedPush) '
              'instalada. Instala ntfy para recibir avisos.',
        );
        return;
      }
      // Sin UI de selección: se toma el primero disponible (suele ser ntfy).
      distributor = distributors.first;
      await _service.saveDistributor(distributor);
    }

    state = state.copyWith(
      state: PushRegistrationState.registering,
      distributor: distributor,
    );
    await _service.register();
  }

  /// Baja del distribuidor: olvida el endpoint y vuelve a inactivo.
  Future<void> unregister() async {
    await _service.unregister();
    await ref.read(pushEndpointProvider.notifier).clear();
    state = const PushStatus.idle();
  }

  void _onNewEndpoint(String endpoint, String instance) {
    unawaited(ref.read(pushEndpointProvider.notifier).save(endpoint));
    state = state.copyWith(
      state: PushRegistrationState.registered,
      endpoint: endpoint,
      message: null,
    );
  }

  void _onRegistrationFailed(String instance) {
    state = state.copyWith(
      state: PushRegistrationState.failed,
      message: 'El distribuidor rechazó el registro.',
    );
  }

  void _onUnregistered(String instance) {
    unawaited(ref.read(pushEndpointProvider.notifier).clear());
    state = const PushStatus(state: PushRegistrationState.unregistered);
  }

  void _onMessage(Uint8List message, String instance) {
    final PushMessage decoded = _service.decodeMessage(message);
    unawaited(_service.showMessage(decoded));
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
/// '/notifications' (gancho de navegación; el router no se edita aquí).
final pushTapProvider = StreamProvider<String>(
  (ref) => ref.watch(pushRegistrationProvider.notifier).taps,
);
