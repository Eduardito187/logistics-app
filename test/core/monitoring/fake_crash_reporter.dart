import 'package:flutter/foundation.dart';
import 'package:logistics_app/core/monitoring/crash_reporter.dart';

/// Reporter en memoria para tests: registra todo lo que recibe.
class FakeCrashReporter implements CrashReporter {
  final List<String> breadcrumbs = [];
  final List<({Object error, bool fatal, String? reason})> errors = [];
  final List<FlutterErrorDetails> flutterErrors = [];
  final Map<String, Object?> keys = {};
  final List<CrashUserContext?> users = [];

  @override
  bool get isEnabled => true;

  @override
  void breadcrumb(String event) => breadcrumbs.add(sanitizeBreadcrumb(event));

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async => errors.add((error: error, fatal: fatal, reason: reason));

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async => flutterErrors.add(details);

  @override
  Future<void> setCustomKey(String key, Object? value) async =>
      keys[key] = value;

  @override
  Future<void> setUser(CrashUserContext? user) async => users.add(user);
}
