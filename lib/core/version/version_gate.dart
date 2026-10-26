import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_build_info.dart';
import 'app_version.dart';

/// Cabeceras del control de versión app ↔ backend.
abstract final class VersionHeaders {
  /// Enviadas por la app en cada request.
  static const appVersion = 'X-App-Version';
  static const appBuild = 'X-App-Build';

  /// Enviada por el backend en las respuestas `/app/*` (pedido en
  /// docs/backend-requests/2026-10-16-version-minima-app.md).
  static const minAppVersion = 'X-Min-App-Version';
}

/// Estado del control de versión. [mustUpdate] bloquea toda la app.
@immutable
class VersionGateState {
  const VersionGateState({
    this.current,
    this.minRequired,
    this.upgradeRequired = false,
  });

  /// Versión instalada (`null` mientras se lee).
  final AppVersion? current;

  /// Mínima exigida por el backend (`null` = el backend no la informó).
  final AppVersion? minRequired;

  /// El backend respondió 426 Upgrade Required (aunque no mande la mínima).
  final bool upgradeRequired;

  /// Bloquear solo con certeza: versión instalada conocida y menor a la
  /// mínima, o un 426 explícito. Ante dudas (sin versión) no se bloquea: es
  /// peor dejar a un chofer sin app que operar con una versión vieja.
  bool get mustUpdate {
    if (upgradeRequired) return true;
    final cur = current;
    final min = minRequired;
    return cur != null && min != null && cur < min;
  }

  VersionGateState copyWith({
    AppVersion? current,
    AppVersion? minRequired,
    bool? upgradeRequired,
  }) => VersionGateState(
    current: current ?? this.current,
    minRequired: minRequired ?? this.minRequired,
    upgradeRequired: upgradeRequired ?? this.upgradeRequired,
  );
}

/// Control de versión: lo alimenta el interceptor de Dio con la cabecera
/// `X-Min-App-Version` (o un 426) y lo consume [VersionGate] para bloquear.
///
/// El bloqueo vive en memoria: tras reiniciar la app, el primer request al
/// backend lo vuelve a activar (sin red no se bloquea: offline-first).
class VersionGateNotifier extends Notifier<VersionGateState> {
  @override
  VersionGateState build() {
    // `listen` y no `watch`: al llegar la versión instalada no se reconstruye
    // el notifier (se perdería la mínima ya informada por el backend).
    ref.listen<AppBuildInfo?>(appBuildInfoProvider, (_, next) {
      final parsed = next?.parsed;
      if (parsed != null) state = state.copyWith(current: parsed);
    });
    return VersionGateState(current: ref.read(appBuildInfoProvider)?.parsed);
  }

  /// Registra la mínima informada por el backend. Valores inválidos o vacíos
  /// se ignoran (no bloquean). La mínima puede bajar (rollback del backend).
  void reportMinVersion(String? raw) {
    final min = AppVersion.tryParse(raw);
    if (min == null || min == state.minRequired) return;
    state = VersionGateState(
      current: state.current,
      minRequired: min,
      upgradeRequired: state.upgradeRequired,
    );
  }

  /// El backend respondió 426 Upgrade Required.
  void reportUpgradeRequired() {
    if (state.upgradeRequired) return;
    state = state.copyWith(upgradeRequired: true);
  }
}

final versionGateProvider =
    NotifierProvider<VersionGateNotifier, VersionGateState>(
      VersionGateNotifier.new,
    );
