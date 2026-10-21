import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../network/auth_headers.dart';
import 'crash_reporter.dart';

/// Identificador seudónimo del usuario para los reportes: hash del usuario de
/// login, nunca el nombre ni el email. Estable entre sesiones del mismo
/// usuario (permite agrupar crashes) sin exponer quién es.
Future<String> pseudonymousUserId(String userName) async {
  final hash = await Sha256().hash(
    utf8.encode('dismac-logistics:${userName.trim().toLowerCase()}'),
  );
  final hex = hash.bytes
      .take(8)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return 'u_$hex';
}

/// Contexto de reporte armado desde la sesión (sin datos personales).
Future<CrashUserContext> crashUserContextFrom(Session session) async =>
    CrashUserContext(
      userId: await pseudonymousUserId(session.userName),
      role: session.role.backendKey,
      storeNodeId: session.storeNode?.id,
    );

/// Mantiene el usuario y las claves de contexto del [CrashReporter] al día con
/// la sesión: al iniciar sesión setea id seudónimo + rol + tienda; al cerrarla
/// los limpia. También deja el `device_id` como clave.
///
/// Se activa con `ref.watch(crashSessionBinderProvider)` en `LogisticsApp`.
final crashSessionBinderProvider = Provider<void>((ref) {
  final reporter = ref.watch(crashReporterProvider);
  // Las llamadas son async (hash): una secuencia descarta resultados viejos si
  // la sesión cambia mientras se calcula el contexto anterior.
  var generation = 0;

  ref.listen<Session?>(sessionProvider, (previous, next) async {
    final current = ++generation;
    if (next == null) {
      if (previous != null) reporter.breadcrumb('session.sign_out');
      await reporter.setUser(null);
      return;
    }
    final context = await crashUserContextFrom(next);
    if (current != generation) return;
    if (previous == null) reporter.breadcrumb('session.sign_in');
    await reporter.setUser(context);
  }, fireImmediately: true);

  ref.listen<String?>(
    authHeadersProvider.select((h) => h.deviceId),
    (_, deviceId) => reporter.setCustomKey(CrashKeys.deviceId, deviceId),
    fireImmediately: true,
  );
});
