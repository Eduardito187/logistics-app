// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/set_setting_accepted.dart';
import '../models/set_setting_request.dart';
import '../models/setting_envelope.dart';
import '../models/setting_history_envelope.dart';

part 'settings_client.g.dart';

@RestApi()
abstract class SettingsClient {
  factory SettingsClient(Dio dio, {String? baseUrl}) = _SettingsClient;

  /// Effective value of a setting key (internal app).
  ///
  /// Returns the value of a namespaced setting key effective at the given date.
  ///
  /// [key] - Namespaced setting key, e.g. coverage.default_service_days.
  ///
  /// [at] - ISO 8601 date to read the value as of. Defaults to now.
  @GET('/app/settings/{key}')
  Future<SettingEnvelope> appGetSetting({
    @Path('key') required String key,
    @Query('at') DateTime? at,
  });

  /// Version history of a setting key (internal app).
  ///
  /// Lists every version of a key, newest first. An unknown key returns an empty list.
  ///
  /// [key] - Namespaced setting key, e.g. coverage.default_service_days.
  @GET('/app/settings/{key}/history')
  Future<SettingHistoryEnvelope> appGetSettingHistory({
    @Path('key') required String key,
  });

  /// Publish a new version of a setting key (service).
  ///
  /// Publishes the next version of a namespaced key. The previous version is never overwritten; the domain assigns the id, version number and effective date. Write is asynchronous.
  @POST('/integrations/settings')
  Future<SetSettingAccepted> integrationsSetSetting({
    @Body() required SetSettingRequest body,
  });

  /// Effective value of a setting key (service).
  ///
  /// Returns the value of a namespaced setting key effective at the given date.
  ///
  /// [key] - Namespaced setting key, e.g. coverage.default_service_days.
  ///
  /// [at] - ISO 8601 date to read the value as of. Defaults to now.
  @GET('/integrations/settings/{key}')
  Future<SettingEnvelope> integrationsGetSetting({
    @Path('key') required String key,
    @Query('at') DateTime? at,
  });

  /// Version history of a setting key (service).
  ///
  /// Lists every version of a key, newest first. An unknown key returns an empty list.
  ///
  /// [key] - Namespaced setting key, e.g. coverage.default_service_days.
  @GET('/integrations/settings/{key}/history')
  Future<SettingHistoryEnvelope> integrationsGetSettingHistory({
    @Path('key') required String key,
  });
}
