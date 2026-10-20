import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// Implementación con Firebase Crashlytics (mismo proyecto que el push FCM).
///
/// Solo se construye si Firebase quedó inicializado (ver
/// `initCrashReporting`). Cada llamada está protegida: un fallo del plugin
/// nunca debe tumbar la app que intenta reportar otro error.
class CrashlyticsCrashReporter implements CrashReporter {
  CrashlyticsCrashReporter(this._crashlytics, {required bool enabled})
    : _enabled = enabled;

  final FirebaseCrashlytics _crashlytics;
  final bool _enabled;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) => _guard(
    () => _crashlytics.recordError(error, stack, fatal: fatal, reason: reason),
  );

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) => _guard(
    () => fatal
        ? _crashlytics.recordFlutterFatalError(details)
        : _crashlytics.recordFlutterError(details),
  );

  @override
  void breadcrumb(String event) {
    _guard(() => _crashlytics.log(sanitizeBreadcrumb(event)));
  }

  @override
  Future<void> setCustomKey(String key, Object? value) =>
      _guard(() => _crashlytics.setCustomKey(key, _keyValue(value)));

  @override
  Future<void> setUser(CrashUserContext? user) => _guard(() async {
    await _crashlytics.setUserIdentifier(user?.userId ?? '');
    await _crashlytics.setCustomKey(CrashKeys.role, user?.role ?? '');
    await _crashlytics.setCustomKey(
      CrashKeys.storeNodeId,
      user?.storeNodeId ?? '',
    );
    await _crashlytics.setCustomKey(CrashKeys.vehicleId, user?.vehicleId ?? '');
  });

  /// Crashlytics acepta String/num/bool; `null` se guarda como vacío.
  static Object _keyValue(Object? value) => switch (value) {
    null => '',
    final String v => v,
    final num v => v,
    final bool v => v,
    final Object v => v.toString(),
  };

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      debugPrint('Crashlytics no disponible: $e');
    }
  }
}
