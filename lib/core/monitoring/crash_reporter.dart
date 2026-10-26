import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Claves de contexto que acompañan a cada reporte. Nunca datos personales:
/// solo identificadores operativos (rol, nodo, vehículo, dispositivo).
abstract final class CrashKeys {
  static const role = 'role';
  static const storeNodeId = 'store_node_id';
  static const vehicleId = 'vehicle_id';
  static const deviceId = 'device_id';
  static const env = 'env';
}

/// Contexto del usuario logueado para los reportes. El [userId] es un
/// identificador seudónimo (nunca email ni nombre).
@immutable
class CrashUserContext {
  const CrashUserContext({
    required this.userId,
    required this.role,
    this.storeNodeId,
    this.vehicleId,
  });

  final String userId;
  final String role;
  final String? storeNodeId;
  final String? vehicleId;
}

/// Puerto de reporte de errores en terreno. La app depende de esta interfaz,
/// no de Crashlytics: sin credenciales de Firebase se usa [NoopCrashReporter].
abstract interface class CrashReporter {
  /// ¿Los reportes salen del teléfono? (solo release y con Firebase).
  bool get isEnabled;

  /// Error capturado (no fatal por defecto).
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  /// Error del framework de Flutter (`FlutterError.onError`).
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  });

  /// Migas de pan: navegación y acciones clave, SIN datos personales.
  void breadcrumb(String event);

  /// Clave de contexto. `null` la limpia.
  Future<void> setCustomKey(String key, Object? value);

  /// Usuario logueado (`null` = sesión cerrada: limpia id y claves).
  Future<void> setUser(CrashUserContext? user);
}

/// Reporter inerte: sin Firebase, en tests y en debug sin credenciales.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  bool get isEnabled => false;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {}

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {}

  @override
  void breadcrumb(String event) {}

  @override
  Future<void> setCustomKey(String key, Object? value) async {}

  @override
  Future<void> setUser(CrashUserContext? user) async {}
}

/// Normaliza una miga de pan para que nunca lleve datos personales ni textos
/// libres: solo `[a-z0-9_.:/-]` y espacio, máximo 120 caracteres. Los segmentos que
/// parecen identificadores (números largos, ULID/UUID) se reemplazan por `:id`.
///
/// Se llama en cada navegación: las expresiones regulares se compilan una sola
/// vez y la entrada se acota antes de procesarla (un texto enorme no genera
/// copias enormes para quedarse con 120 caracteres).
String sanitizeBreadcrumb(String event) {
  var lower = event.trim().toLowerCase();
  if (lower.length > _breadcrumbInputMax) {
    lower = lower.substring(0, _breadcrumbInputMax);
  }
  final segments = lower.split('/').map((segment) {
    if (_longNumber.hasMatch(segment) ||
        _ulid.hasMatch(segment) ||
        _uuid.hasMatch(segment)) {
      return ':id';
    }
    return segment;
  });
  final cleaned = segments.join('/').replaceAll(_disallowed, '_');
  return cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
}

const int _breadcrumbInputMax = 512;
final RegExp _longNumber = RegExp(r'^[0-9]{3,}$');
final RegExp _ulid = RegExp(r'^[0-9a-z]{26}$');
final RegExp _uuid = RegExp(r'^[0-9a-f-]{32,36}$');
final RegExp _disallowed = RegExp(r'[^a-z0-9_.:/\- ]');

/// Reporter activo. Por defecto inerte; `main.dart` lo sobreescribe con el
/// que devuelve `initCrashReporting()`.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => const NoopCrashReporter(),
);
