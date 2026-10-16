import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_queue.dart';
import 'photo_upload_queue.dart';

/// Estado de conectividad; dispara el drenado de la cola al recuperar señal.
class ConnectivityNotifier extends AsyncNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  Future<bool> build() async {
    final connectivity = Connectivity();
    _sub = connectivity.onConnectivityChanged.listen(_onChange);
    ref.onDispose(() => _sub?.cancel());
    final current = await connectivity.checkConnectivity();
    return _isOnline(current);
  }

  void _onChange(List<ConnectivityResult> results) {
    final online = _isOnline(results);
    state = AsyncData(online);
    if (online) {
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
