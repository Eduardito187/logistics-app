import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/session.dart';
import 'app_shortcut.dart';
import 'app_shortcuts_service.dart';

/// Mantiene los accesos directos del ícono al día con la sesión y abre la
/// pantalla del acceso tocado.
///
/// - Al iniciar sesión publica los accesos del rol; al cerrarla los borra (el
///   ícono no ofrece flujos de alguien que ya no está logueado).
/// - Un acceso tocado sin sesión queda PENDIENTE y se abre apenas el usuario
///   entra (si su rol lo tiene).
/// - Solo navega a rutas que la sesión ofrece como acceso o como widget de la
///   pantalla de inicio de su rol (`extraRoutesOf`): un intent ajeno con una
///   ruta cualquiera no abre pantallas de otro rol.
class AppShortcutsController {
  AppShortcutsController({
    required AppShortcutsService service,
    required void Function(String route) navigate,
    required List<AppShortcut> Function(Session session) shortcutsOf,
    Set<String> Function(Session session)? extraRoutesOf,
  }) : _service = service,
       _navigate = navigate,
       _shortcutsOf = shortcutsOf,
       _extraRoutesOf = extraRoutesOf;

  final AppShortcutsService _service;
  final void Function(String route) _navigate;
  final List<AppShortcut> Function(Session session) _shortcutsOf;

  /// Otras rutas conocidas que también se pueden abrir desde fuera de la app
  /// (las de los widgets de la pantalla de inicio del rol).
  final Set<String> Function(Session session)? _extraRoutesOf;

  Session? _session;
  String? _pending;

  /// Lo último publicado en el launcher (`null` = todavía nada).
  List<AppShortcut>? _published;

  /// Ruta esperando sesión (para tests y diagnóstico).
  String? get pendingRoute => _pending;

  /// Cambió la sesión (login, restore, logout).
  void onSession(Session? session) {
    _session = session;
    if (session == null) {
      if (_published == null || _published!.isNotEmpty) {
        unawaited(_service.clear());
      }
      _published = const [];
      return;
    }
    final shortcuts = _shortcutsOf(session);
    if (!listEquals(shortcuts, _published)) {
      unawaited(shortcuts.isEmpty ? _service.clear() : _service.set(shortcuts));
      _published = shortcuts;
    }
    _flush();
  }

  /// Se tocó un acceso (o el "Abrir" de la notificación de ruta en vivo).
  void onLaunch(String route) {
    _pending = route;
    _flush();
  }

  /// Arranque en frío: ¿la app se abrió desde un acceso?
  Future<void> consumeAtStartup() async {
    final route = await _service.consumeLaunchShortcut();
    if (route != null) onLaunch(route);
  }

  void _flush() {
    final route = _pending;
    final session = _session;
    if (route == null || session == null) return;
    _pending = null;
    final allowed =
        _shortcutsOf(session).any((s) => s.route == route) ||
        (_extraRoutesOf?.call(session).contains(route) ?? false);
    if (allowed) _navigate(route);
  }
}
