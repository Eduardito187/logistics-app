import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_queue.dart';
import 'photo_upload_queue.dart';

/// Estado de conectividad; dispara el drenado de la cola al recuperar señal.
class ConnectivityNotifier extends AsyncNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Último estado conocido (en línea / sin red). Se usa para drenar SOLO en el
  /// flanco real sin-red → con-red, no en cada evento de conectividad.
  bool _online = false;

  @override
  Future<bool> build() async {
    final connectivity = Connectivity();
    _sub = connectivity.onConnectivityChanged.listen(_onChange);
    ref.onDispose(() => _sub?.cancel());
    final current = await connectivity.checkConnectivity();
    _online = _isOnline(current);
    return _online;
  }

  void _onChange(List<ConnectivityResult> results) {
    final online = _isOnline(results);
    final wasOnline = _online;
    _online = online;
    state = AsyncData(online);
    // Drenar SOLO en la transición real sin-red → con-red. `connectivity_plus`
    // emite un evento por cada cambio de interfaz (Wi-Fi ↔ datos, VPN que sube,
    // reconexión que titila con el camión en movimiento): si se drenara en cada
    // evento "en línea" se repetirían lecturas de la cola y POSTs sin fin, lo
    // que carga la CPU y calienta el equipo en terreno. Con el flanco alcanza;
    // los reintentos con backoff y la tarea de fondo cubren el resto.
    if (online && !wasOnline) {
      // Al recuperar señal, drenar ambas colas en segundo plano: acciones JSON
      // y fotos de evidencia pendientes.
      unawaited(ref.read(offlineQueueProvider).drain());
      unawaited(ref.read(photoUploadQueueProvider).drain());
    }
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

final connectivityProvider = AsyncNotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);
