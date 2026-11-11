import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shortcut.dart';

/// Puente con el canal nativo `bo.com.dismac/shortcuts`:
/// - Android (`AppShortcutsChannel.kt`): `ShortcutManager` (API 25+).
/// - iOS (`AppShortcutsChannel.swift`): `UIApplication.shortcutItems`.
///
/// Dart → nativo: "set" (lista de accesos), "clear", "consumeLaunchShortcut"
/// (ruta del acceso con el que se ABRIÓ la app, o `null`; se entrega una vez).
/// Nativo → Dart: "launch" (ruta) cuando se toca un acceso con la app ya
/// abierta (Android `onNewIntent`, iOS `performActionFor`). También lo usa el
/// botón "Abrir" de la notificación de ruta en vivo (Android).
///
/// Nunca falla: sin canal (tests, escritorio) todo es no-op.
class AppShortcutsService {
  AppShortcutsService({MethodChannel channel = defaultChannel})
    : _channel = channel;

  static const MethodChannel defaultChannel = MethodChannel(
    'bo.com.dismac/shortcuts',
  );

  final MethodChannel _channel;
  StreamController<String>? _launches;

  /// Rutas de accesos tocados con la app ya abierta.
  Stream<String> get launches {
    final existing = _launches;
    if (existing != null) return existing.stream;
    final controller = StreamController<String>.broadcast();
    _launches = controller;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'launch') return null;
      final route = call.arguments;
      if (route is String && route.startsWith('/')) controller.add(route);
      return null;
    });
    return controller.stream;
  }

  Future<void> set(List<AppShortcut> shortcuts) => _invoke('set', [
    for (final s in shortcuts) s.toMap(),
  ]);

  Future<void> clear() => _invoke('clear');

  /// Ruta del acceso que abrió la app (una sola vez), o `null`.
  Future<String?> consumeLaunchShortcut() async {
    try {
      final route = await _channel.invokeMethod<String>(
        'consumeLaunchShortcut',
      );
      return route != null && route.startsWith('/') ? route : null;
    } on Object {
      return null;
    }
  }

  /// Suelta la escucha del canal (dispose del provider).
  void dispose() {
    final controller = _launches;
    if (controller == null) return;
    _launches = null;
    _channel.setMethodCallHandler(null);
    unawaited(controller.close());
  }

  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<Object?>(method, arguments);
    } on Object {
      // Sin canal o error del launcher: los accesos son un extra.
    }
  }
}

/// Servicio de accesos directos. Seam para tests (`overrideWithValue`).
final appShortcutsServiceProvider = Provider<AppShortcutsService>((ref) {
  final service = AppShortcutsService();
  ref.onDispose(service.dispose);
  return service;
});
