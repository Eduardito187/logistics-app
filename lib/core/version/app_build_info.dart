import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.dart';

/// Versión instalada de la app (de `pubspec.yaml` → `version: x.y.z+build`).
@immutable
class AppBuildInfo {
  const AppBuildInfo({required this.version, required this.buildNumber});

  /// `x.y.z` tal como lo reporta la plataforma.
  final String version;

  /// Número de build (`versionCode` en Android).
  final String buildNumber;

  AppVersion? get parsed => AppVersion.tryParse(version);
}

/// Fuente de la versión instalada. Se sobreescribe en tests.
final appBuildInfoLoaderProvider = Provider<Future<AppBuildInfo> Function()>(
  (ref) => () async {
    final info = await PackageInfo.fromPlatform();
    return AppBuildInfo(version: info.version, buildNumber: info.buildNumber);
  },
);

/// Versión instalada, cargada una vez al arrancar. `null` mientras carga o si
/// la plataforma no la entrega (los requests salen sin `X-App-Version`).
class AppBuildInfoNotifier extends Notifier<AppBuildInfo?> {
  Future<void>? _loading;

  @override
  AppBuildInfo? build() {
    // Se dispara solo; `main.dart` puede esperarla con [ensureLoaded] para
    // que el primer request ya lleve la versión.
    unawaited(ensureLoaded());
    return null;
  }

  /// Carga (una sola vez) la versión instalada. Nunca lanza.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final info = await ref.read(appBuildInfoLoaderProvider)();
      if (ref.mounted) state = info;
    } on Object catch (e) {
      debugPrint('No se pudo leer la versión de la app: $e');
    }
  }
}

final appBuildInfoProvider =
    NotifierProvider<AppBuildInfoNotifier, AppBuildInfo?>(
      AppBuildInfoNotifier.new,
    );
