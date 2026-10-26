import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/two_factor_challenge.dart';
import '../../domain/entities/two_factor_enrollment.dart';

/// Resultado crudo del login: o el éxito (token+user) o el reto 2FA.
typedef LoginRaw = ({AppLoginResponse? success, TwoFactorChallenge? challenge});

/// Única clase del feature auth que toca la red. Login, 2FA y reseteo de
/// contraseña.
///
/// NOTA (regla #5): `login`/`me` usan el cliente generado. Los endpoints de 2FA
/// y password NO están en el OpenAPI del que se genera el cliente, así que se
/// llaman con Dio directo contra las rutas del backend (ya implementadas). Al
/// regenerar el cliente con el spec que los incluya, conviene migrarlos a
/// `api.auth.*`. El JSON de éxito se parsea con los modelos generados
/// ([AppLoginResponse]); no se escriben DTOs a mano para esa forma.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Map<String, Object?> _asMap(Object? data) =>
      data is Map ? data.cast<String, Object?>() : const <String, Object?>{};

  /// POST `/app/auth/login`. La respuesta 200 tiene DOS formas: éxito
  /// (token+user) o reto 2FA (`two_factor_required`). Se mira el JSON crudo
  /// porque el tipo generado solo modela la forma de éxito.
  Future<LoginRaw> login(AppLoginRequest request) async {
    try {
      final res = await _dio.post<Object?>(
        '/app/auth/login',
        data: request.toJson(),
      );
      final json = _asMap(res.data);
      if (json['two_factor_required'] == true) {
        return (success: null, challenge: TwoFactorChallenge.fromJson(json));
      }
      return (success: AppLoginResponse.fromJson(json), challenge: null);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/auth/2fa/verify` (público). Verifica el código (TOTP o recovery)
  /// contra el reto. 200 → misma forma de éxito que el login.
  Future<AppLoginResponse> verifyTwoFactor({
    required String challengeId,
    required String code,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/app/auth/2fa/verify',
        data: {'challenge_id': challengeId, 'code': code},
      );
      return AppLoginResponse.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET `/app/auth/me`. Perfil + abilities del token vigente (Bearer puesto).
  Future<AppMeResponse> me() async {
    final api = _ref.read(logisticsApiProvider);
    try {
      return await api.auth.appMe();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/auth/2fa/enroll` (Bearer). Secreto + URI otpauth + 8 recovery.
  Future<TwoFactorEnrollment> enrollTwoFactor() async {
    try {
      final res = await _dio.post<Object?>('/app/auth/2fa/enroll');
      return TwoFactorEnrollment.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/auth/2fa/confirm` (Bearer). Activa el 2FA con un código válido.
  Future<void> confirmTwoFactor(String code) async {
    try {
      await _dio.post<Object?>('/app/auth/2fa/confirm', data: {'code': code});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/auth/2fa/disable` (Bearer). Con código TOTP/recovery o con la
  /// contraseña actual.
  Future<void> disableTwoFactor({String? code, String? password}) async {
    assert(
      (code != null) ^ (password != null),
      'Pasá código O contraseña, no ambos.',
    );
    try {
      await _dio.post<Object?>(
        '/app/auth/2fa/disable',
        data: code != null ? {'code': code} : {'password': password},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/auth/password/forgot`. SIEMPRE 200 genérico (no revela si el
  /// correo existe).
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post<Object?>(
        '/app/auth/password/forgot',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/auth/password/reset`. Cambia la contraseña con el código (OTP)
  /// que llegó al correo. 422 si el código es inválido/expirado o la contraseña
  /// no cumple.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      await _dio.post<Object?>(
        '/app/auth/password/reset',
        data: {'email': email, 'code': code, 'password': password},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  AuthRemoteDataSource.new,
);
