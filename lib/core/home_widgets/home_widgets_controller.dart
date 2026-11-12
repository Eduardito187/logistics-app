import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/user_role.dart';
import 'home_widget_builders.dart';
import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';
import 'home_widget_status_payload.dart';
import 'home_widgets_service.dart';
import 'role_home_widgets.dart';

/// Decide CUÁNDO tocar el canal nativo de los widgets. La batería es crítica:
/// - Payload igual a lo último enviado (sin contar `updatedAt`) → nada.
/// - Cambio de estado o de parada (`isMajorChangeFrom`) → al instante.
/// - Cualquier otro cambio → como máximo uno por kind cada
///   [minUpdateInterval]; lo retenido sale con la siguiente foto que lo
///   permita o al pasar la app a segundo plano ([flush]). Sin timers propios.
///
/// Sesión:
/// - [signIn] (rol confirmado + preferencias del usuario cargadas):
///   "setEnabledKinds" con (kinds del rol − apagados por el usuario) ∪
///   "quick_scan", "notAllowed" a los kinds fuera del rol y un payload inicial
///   a cada kind del rol ("Escanear" listo; los de datos en "empty" hasta que
///   el inicio cargue lo suyo).
/// - [signOut]: SOLO "clearAll" (los widgets puestos quedan invitando a
///   iniciar sesión). Nunca "setEnabledKinds": en Android deshabilitar un
///   provider QUITA de la pantalla de inicio los widgets ya colocados.
class HomeWidgetsController {
  HomeWidgetsController({
    required HomeWidgetsService service,
    DateTime Function()? clock,
    this.minUpdateInterval = const Duration(seconds: 60),
  }) : _service = service,
       _clock = clock ?? DateTime.now;

  final HomeWidgetsService _service;
  final DateTime Function() _clock;

  /// Intervalo mínimo entre updates menores del mismo kind.
  final Duration minUpdateInterval;

  String? _userKey;
  UserRole? _role;
  bool _signedOutApplied = false;
  List<HomeWidgetKind>? _enabled;

  /// Última foto recibida por kind (se haya enviado o no).
  final Map<HomeWidgetKind, HomeWidgetPayload> _latest = {};

  /// Último payload enviado al nativo por kind, y cuándo.
  final Map<HomeWidgetKind, HomeWidgetPayload> _sent = {};
  final Map<HomeWidgetKind, DateTime> _sentAt = {};

  /// Rol de la sesión configurada (`null` sin sesión).
  UserRole? get role => _role;

  /// Kinds habilitados en el selector (lo último enviado en
  /// "setEnabledKinds"); `null` antes del primer login.
  List<HomeWidgetKind>? get enabledKinds => _enabled;

  /// Último payload enviado de [kind] (tests y diagnóstico).
  HomeWidgetPayload? lastSent(HomeWidgetKind kind) => _sent[kind];

  /// Kinds a habilitar para [role] sin los [disabled] por el usuario. "Escanear"
  /// va SIEMPRE (también queda puesto para el login del próximo usuario).
  static List<HomeWidgetKind> enabledKindsFor(
    UserRole role,
    Set<HomeWidgetKind> disabled,
  ) {
    final roleKinds = homeWidgetKindsFor(role);
    return [
      for (final kind in HomeWidgetKind.values)
        if (kind == HomeWidgetKind.quickScan ||
            (roleKinds.contains(kind) && !disabled.contains(kind)))
          kind,
    ];
  }

  /// Sesión confirmada de [userKey] con [role] y sus widgets apagados
  /// [disabled]. Idempotente: llamarlo de nuevo solo envía lo que cambió.
  void signIn({
    required String userKey,
    required UserRole role,
    Set<HomeWidgetKind> disabled = const {},
  }) {
    final roleKinds = homeWidgetKindsFor(role);
    if (_userKey != userKey || _role != role) {
      _resetCaches();
      _userKey = userKey;
      _role = role;
      _signedOutApplied = false;
      _enabled = null;
      for (final kind in HomeWidgetKind.values) {
        if (roleKinds.contains(kind)) continue;
        _send(
          HomeWidgetStatusPayload(
            kind: kind,
            state: HomeWidgetState.notAllowed,
            route: kHomeWidgetNotAllowedRoute,
          ),
          force: true,
        );
      }
    }
    final enabled = enabledKindsFor(role, disabled);
    final previous = _enabled;
    if (previous != null && listEquals(previous, enabled)) return;
    _enabled = enabled;
    unawaited(_service.setEnabledKinds(enabled));
    for (final kind in roleKinds) {
      if (!enabled.contains(kind)) continue;
      if (previous != null && previous.contains(kind)) continue;
      // Recién habilitado: lo último conocido, o el estado inicial.
      _sent.remove(kind);
      _send(_latest[kind] ?? _initialPayload(kind, role), force: true);
    }
  }

  /// Sin sesión: borra los datos de los widgets (una vez por cierre).
  void signOut() {
    if (_signedOutApplied) return;
    _signedOutApplied = true;
    _userKey = null;
    _role = null;
    _resetCaches();
    unawaited(_service.clearAll());
  }

  /// Nueva foto de un widget. Se ignora sin sesión, si no es del rol o si el
  /// usuario lo apagó (se guarda igual por si lo vuelve a prender).
  void onPayload(HomeWidgetPayload payload) {
    final role = _role;
    if (role == null || !homeWidgetKindsFor(role).contains(payload.kind)) {
      return;
    }
    _latest[payload.kind] = payload;
    if (!(_enabled?.contains(payload.kind) ?? false)) return;
    _send(payload);
  }

  /// La app pasó a segundo plano: publica lo retenido por el intervalo
  /// mínimo (es cuando el usuario mira los widgets).
  void flush() {
    final enabled = _enabled;
    if (_role == null || enabled == null) return;
    for (final kind in enabled) {
      final latest = _latest[kind];
      if (latest != null) _send(latest, force: true);
    }
  }

  void _send(HomeWidgetPayload payload, {bool force = false}) {
    final kind = payload.kind;
    final last = _sent[kind];
    if (last != null && last.sameContentAs(payload)) return;
    final now = _clock();
    if (!force && last != null && !payload.isMajorChangeFrom(last)) {
      final at = _sentAt[kind];
      if (at != null && now.difference(at) < minUpdateInterval) return;
    }
    _sent[kind] = payload;
    _sentAt[kind] = now;
    unawaited(_service.update(kind, payload.toMap(updatedAt: now)));
  }

  HomeWidgetPayload _initialPayload(HomeWidgetKind kind, UserRole role) {
    if (kind == HomeWidgetKind.quickScan) {
      final scan = quickScanPayloadFor(role);
      if (scan != null) return scan;
    }
    return HomeWidgetStatusPayload(
      kind: kind,
      state: HomeWidgetState.empty,
      route: homeWidgetRouteFor(kind, role) ?? kHomeWidgetNotAllowedRoute,
    );
  }

  void _resetCaches() {
    _latest.clear();
    _sent.clear();
    _sentAt.clear();
  }
}
