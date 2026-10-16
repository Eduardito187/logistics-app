// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_login_request.dart';
import '../models/app_login_response.dart';
import '../models/app_me_response.dart';
import '../models/app_token_response.dart';
import '../models/get_app_devices_response.dart';
import '../models/get_channels_auth_ping_response.dart';
import '../models/get_integrations_auth_ping_response.dart';
import '../models/message_response.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Log in with user credentials bound to a device (gate /app).
  ///
  /// Public endpoint (rate limited). Validates the user's credentials, binds the device and issues a new Sanctum token, revoking previous tokens for that same device.
  @POST('/app/auth/login')
  Future<AppLoginResponse> appLogin({@Body() required AppLoginRequest body});

  /// Log out, revoking only the token in use (gate /app)
  @POST('/app/auth/logout')
  Future<MessageResponse> appLogout();

  /// Rotate the current token for the same device (gate /app)
  @POST('/app/auth/refresh')
  Future<AppTokenResponse> appRefresh();

  /// Current user profile, device and abilities (gate /app)
  @GET('/app/auth/me')
  Future<AppMeResponse> appMe();

  /// List the authenticated user's devices (gate /app)
  @GET('/app/devices')
  Future<GetAppDevicesResponse> listDevices();

  /// Revoke one of the user's devices by UUID (gate /app).
  ///
  /// [uuid] - Device UUID (UUID v7).
  @DELETE('/app/devices/{uuid}')
  Future<MessageResponse> revokeDevice({@Path('uuid') required String uuid});

  /// Verify channel credentials (gate /channels)
  @GET('/channels/auth/ping')
  Future<GetChannelsAuthPingResponse> channelPing();

  /// Verify service credentials (gate /integrations)
  @GET('/integrations/auth/ping')
  Future<GetIntegrationsAuthPingResponse> servicePing();
}
