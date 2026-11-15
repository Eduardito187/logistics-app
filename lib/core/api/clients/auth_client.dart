// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_auth2fa_confirm_request_body.dart';
import '../models/app_auth2fa_disable_request_body.dart';
import '../models/app_auth2fa_verify_request_body.dart';
import '../models/app_auth_password_forgot_request_body.dart';
import '../models/app_auth_password_reset_request_body.dart';
import '../models/app_config.dart';
import '../models/app_devices_current_push_token_request_body.dart';
import '../models/app_login_request.dart';
import '../models/app_login_response.dart';
import '../models/app_me_response.dart';
import '../models/app_token_response.dart';
import '../models/get_app_devices_response.dart';
import '../models/get_channels_auth_ping_response.dart';
import '../models/get_integrations_auth_ping_response.dart';
import '../models/message_response.dart';
import '../models/outbox_failures_accepted.dart';
import '../models/outbox_failures_request.dart';
import '../models/patch_app_devices_uuid_response.dart';
import '../models/post_app_auth_login_response_sealed.dart';
import '../models/rename_device_request.dart';
import '../models/two_factor_enrollment.dart';
import '../models/update_user_preferences_request.dart';
import '../models/user_preferences.dart';
import '../models/x_app_platform.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Log in with user credentials bound to a device (gate /app).
  ///
  /// Public endpoint (rate limited). Validates the user's credentials, binds the device and issues a new Sanctum token, revoking previous tokens for that same device.
  ///
  /// Sesión 1-por-plataforma (estilo app de banco): hay a lo sumo UNA sesión activa por BUCKET (`web` | `app`) por usuario. `web` y `app` coexisten; iniciar sesión en uno no cierra el otro. Un segundo dispositivo del MISMO bucket DESALOJA al anterior: ese equipo recibe, en su próximo request a la puerta /app, un 401 con `code=session_superseded` (distinto del token expirado), para que la app avise "iniciaste sesión en otro dispositivo" y cierre. El bucket se deriva de `device.platform` (android/ios = app; web/desktop = web) o se fuerza con `device.client_kind`.
  @POST('/app/auth/login')
  Future<PostAppAuthLoginResponseSealed> appLogin({
    @Body() required AppLoginRequest body,
  });

  /// Log out, revoking only the token in use (gate /app)
  @POST('/app/auth/logout')
  Future<MessageResponse> appLogout();

  /// Rotate the current token for the same device (gate /app)
  @POST('/app/auth/refresh')
  Future<AppTokenResponse> appRefresh();

  /// Current user profile, device and abilities (gate /app)
  @GET('/app/auth/me')
  Future<AppMeResponse> appMe();

  /// Start two-factor enrollment for the current user (gate /app).
  ///
  /// Genera un secreto TOTP, su URI otpauth y códigos de recuperación para el usuario autenticado. El segundo factor no queda activo hasta confirmarlo en /app/auth/2fa/confirm.
  @POST('/app/auth/2fa/enroll')
  Future<TwoFactorEnrollment> appTwoFactorEnroll();

  /// Confirm and activate two-factor enrollment (gate /app).
  ///
  /// Confirma el enrolamiento validando un código TOTP generado por la app autenticadora. Una vez confirmado, el segundo factor queda activo para el usuario.
  @POST('/app/auth/2fa/confirm')
  Future<MessageResponse> appTwoFactorConfirm({
    @Body() required AppAuth2faConfirmRequestBody body,
  });

  /// Resolve a two-factor challenge and start the session (gate /app).
  ///
  /// Endpoint público (rate limited). Resuelve el desafío de segundo factor emitido por /app/auth/login y, si el código es válido, emite la sesión (token) de la misma forma que un login normal.
  @POST('/app/auth/2fa/verify')
  Future<AppLoginResponse> appTwoFactorVerify({
    @Body() required AppAuth2faVerifyRequestBody body,
  });

  /// Disable two-factor for the current user (gate /app).
  ///
  /// Desactiva el segundo factor del usuario autenticado. Debe acreditarse con un código TOTP vigente o con la contraseña de la cuenta.
  ///
  /// [body] - Acreditar con un código TOTP vigente o con la contraseña de la cuenta.
  @POST('/app/auth/2fa/disable')
  Future<MessageResponse> appTwoFactorDisable({
    @Body() required AppAuth2faDisableRequestBody body,
  });

  /// Request a password reset OTP by email (gate /app).
  ///
  /// Endpoint público (rate limited). Envía un código OTP de un solo uso al correo del usuario para reiniciar la contraseña. Responde siempre igual para no revelar si el correo existe.
  @POST('/app/auth/password/forgot')
  Future<MessageResponse> appPasswordForgot({
    @Body() required AppAuthPasswordForgotRequestBody body,
  });

  /// Reset the password with the emailed OTP (gate /app).
  ///
  /// Endpoint público (rate limited). Reinicia la contraseña del usuario validando el código OTP enviado por correo.
  @POST('/app/auth/password/reset')
  Future<MessageResponse> appPasswordReset({
    @Body() required AppAuthPasswordResetRequestBody body,
  });

  /// List the authenticated user's devices (gate /app)
  @GET('/app/devices')
  Future<GetAppDevicesResponse> listDevices();

  /// Update the push token (FCM FID) of the current device (gate /app).
  ///
  /// Sets the FCM push token (Firebase Installation ID) of the device bound to the current Sanctum token. A null token opts the device out of push. Idempotent.
  @PUT('/app/devices/current/push-token')
  Future<void> updateDevicePushToken({
    @Body() required AppDevicesCurrentPushTokenRequestBody body,
  });

  /// Revoke one of the user's devices by UUID (gate /app).
  ///
  /// [uuid] - Device UUID (UUID v7).
  @DELETE('/app/devices/{uuid}')
  Future<MessageResponse> revokeDevice({@Path('uuid') required String uuid});

  /// Rename one of the user's devices (uuid or 'current').
  ///
  /// [uuid] - Device UUID, or the literal 'current' for the device of the token.
  @PATCH('/app/devices/{uuid}')
  Future<PatchAppDevicesUuidResponse> renameDevice({
    @Path('uuid') required String uuid,
    @Body() required RenameDeviceRequest body,
  });

  /// Server-driven configuration for the app (public, never version-gated).
  ///
  /// Minimum/latest app version and update URL per platform, feature flags, map tiles, support contact, polling intervals and field tunables. Cacheable 5 minutes; varies by X-App-Platform.
  @GET('/app/app-config')
  Future<AppConfig> getAppConfig({
    @Header('X-App-Platform') XAppPlatform? xAppPlatform,
  });

  /// Preferences of the authenticated user (travel across phones)
  @GET('/app/me/preferences')
  Future<UserPreferences> getMyPreferences();

  /// Merge preferences of the authenticated user (last-write-wins per key)
  @PUT('/app/me/preferences')
  Future<UserPreferences> updateMyPreferences({
    @Body() required UpdateUserPreferencesRequest body,
  });

  /// Report client-side queued actions the server rejected permanently.
  ///
  /// Idempotent per failure id. User, device and app version come from the token and headers.
  @POST('/app/outbox-failures')
  Future<OutboxFailuresAccepted> reportOutboxFailures({
    @Body() required OutboxFailuresRequest body,
  });

  /// Verify channel credentials (gate /channels)
  @GET('/channels/auth/ping')
  Future<GetChannelsAuthPingResponse> channelPing();

  /// Verify service credentials (gate /integrations)
  @GET('/integrations/auth/ping')
  Future<GetIntegrationsAuthPingResponse> servicePing();
}
