import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../version/app_build_info.dart';
import '../version/version_gate.dart';

/// Control de versión app ↔ backend en cada request de la puerta `/app/*`:
///
/// - Envía `X-App-Version` y `X-App-Build` (para que el backend sepa qué
///   versión opera y pueda rechazar las viejas).
/// - Lee `X-Min-App-Version` de toda respuesta (también de errores) y un 426
///   Upgrade Required, y se los pasa a `versionGateProvider`, que bloquea la
///   app con "Actualizá la app" si la instalada es menor.
class AppVersionInterceptor extends Interceptor {
  AppVersionInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final info = _ref.read(appBuildInfoProvider);
    if (info != null) {
      options.headers[VersionHeaders.appVersion] = info.version;
      options.headers[VersionHeaders.appBuild] = info.buildNumber;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _inspect(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) _inspect(response);
    handler.next(err);
  }

  void _inspect(Response<dynamic> response) {
    try {
      final gate = _ref.read(versionGateProvider.notifier);
      final min = response.headers.value(VersionHeaders.minAppVersion);
      if (min != null) gate.reportMinVersion(min);
      if (response.statusCode == 426) gate.reportUpgradeRequired();
    } on Object {
      // El control de versión nunca debe romper un request.
    }
  }
}
