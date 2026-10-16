// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/coverage_feature_collection.dart';
import '../models/get_app_coverage_zones_resolve_response.dart';
import '../models/get_app_coverage_zones_response.dart';
import '../models/get_integrations_coverage_zones_resolve_response.dart';
import '../models/get_integrations_coverage_zones_response.dart';
import '../models/post_integrations_coverage_map_import_kml_response.dart';
import '../models/post_integrations_coverage_map_import_response.dart';

part 'coverage_client.g.dart';

@RestApi()
abstract class CoverageClient {
  factory CoverageClient(Dio dio, {String? baseUrl}) = _CoverageClient;

  /// List coverage zones.
  ///
  /// Lista todas las zonas de cobertura con su polígono GeoJSON y reglas (visor de zonas).
  @GET('/app/coverage/zones')
  Future<GetAppCoverageZonesResponse> listCoverageZones();

  /// Resolve which coverage zone contains a point.
  ///
  /// Devuelve la zona de cobertura que contiene el punto (lat, lng) con su nodo de atención y reglas. Responde 404 si ningún polígono contiene el punto.
  @GET('/app/coverage/zones/resolve')
  Future<GetAppCoverageZonesResolveResponse> resolveCoverageZoneForPoint({
    @Query('lat') required double lat,
    @Query('lng') required double lng,
  });

  /// Import the coverage map from a GeoJSON FeatureCollection.
  ///
  /// Empuja el mapa de cobertura vigente como FeatureCollection de GeoJSON. El procesamiento es asíncrono (bus transaccional + outbox): responde 202 al aceptar el comando.
  @POST('/integrations/coverage/map:import')
  Future<PostIntegrationsCoverageMapImportResponse> importCoverageMap({
    @Body() required CoverageFeatureCollection body,
  });

  /// Import the coverage map from a KML document.
  ///
  /// Empuja el mapa de cobertura vigente como documento KML (export de Google Earth / Maps). El cuerpo es el XML crudo; cada <Placemark> se convierte en una zona. El procesamiento es asíncrono (bus transaccional + outbox): responde 202 al aceptar el comando.
  @POST('/integrations/coverage/map:import-kml')
  Future<PostIntegrationsCoverageMapImportKmlResponse> importCoverageMapKml({
    @Body() required File body,
  });

  /// List coverage zones (service credentials)
  @GET('/integrations/coverage/zones')
  Future<GetIntegrationsCoverageZonesResponse> listCoverageZonesIntegration();

  /// Resolve which coverage zone contains a point (service credentials)
  @GET('/integrations/coverage/zones/resolve')
  Future<GetIntegrationsCoverageZonesResolveResponse>
  resolveCoverageZoneForPointIntegration({
    @Query('lat') required double lat,
    @Query('lng') required double lng,
  });
}
