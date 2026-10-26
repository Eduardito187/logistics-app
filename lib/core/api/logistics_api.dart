// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/system_client.dart';
import 'clients/capacity_client.dart';
import 'clients/carriers_client.dart';
import 'clients/coverage_client.dart';
import 'clients/execution_client.dart';
import 'clients/fleet_client.dart';
import 'clients/fleet_ops_client.dart';
import 'clients/labels_client.dart';
import 'clients/network_client.dart';
import 'clients/notifications_client.dart';
import 'clients/outbox_client.dart';
import 'clients/planning_client.dart';
import 'clients/sap_connector_client.dart';
import 'clients/settings_client.dart';
import 'clients/shipments_client.dart';
import 'clients/tracking_client.dart';
import 'clients/promise_client.dart';
import 'clients/access_client.dart';
import 'clients/telemetry_client.dart';
import 'clients/auth_client.dart';
import 'clients/sellers_client.dart';
import 'clients/inbound_client.dart';
import 'clients/inventory_client.dart';
import 'clients/settlement_client.dart';
import 'clients/returns_client.dart';
import 'clients/seller_portal_client.dart';

/// Dismac Logistics API `v1.0.0`.
///
/// Contrato de la plataforma logística Dismac. Es la FUENTE DE VERDAD entre este backend y la.
/// app interna (logistics-app), que genera su cliente Dart a partir de este archivo.
///
/// Tres puertas:.
///   - /api/v1/app/*          → app interna Flutter (tokens por usuario + dispositivo).
///   - /api/v1/channels/*     → app de clientes, web, call center (credenciales por canal).
///   - /api/v1/integrations/* → SAP, transportistas, webhooks (credenciales de servicio).
///
/// Regla: todo endpoint nuevo se agrega acá en el mismo cambio que lo implementa.
/// Un cambio incompatible exige /v2: siempre habrá choferes con una versión vieja de la app.
///
class LogisticsApi {
  LogisticsApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  SystemClient? _system;
  CapacityClient? _capacity;
  CarriersClient? _carriers;
  CoverageClient? _coverage;
  ExecutionClient? _execution;
  FleetClient? _fleet;
  FleetOpsClient? _fleetOps;
  LabelsClient? _labels;
  NetworkClient? _network;
  NotificationsClient? _notifications;
  OutboxClient? _outbox;
  PlanningClient? _planning;
  SapConnectorClient? _sapConnector;
  SettingsClient? _settings;
  ShipmentsClient? _shipments;
  TrackingClient? _tracking;
  PromiseClient? _promise;
  AccessClient? _access;
  TelemetryClient? _telemetry;
  AuthClient? _auth;
  SellersClient? _sellers;
  InboundClient? _inbound;
  InventoryClient? _inventory;
  SettlementClient? _settlement;
  ReturnsClient? _returns;
  SellerPortalClient? _sellerPortal;

  SystemClient get system => _system ??= SystemClient(_dio, baseUrl: _baseUrl);

  CapacityClient get capacity =>
      _capacity ??= CapacityClient(_dio, baseUrl: _baseUrl);

  CarriersClient get carriers =>
      _carriers ??= CarriersClient(_dio, baseUrl: _baseUrl);

  CoverageClient get coverage =>
      _coverage ??= CoverageClient(_dio, baseUrl: _baseUrl);

  ExecutionClient get execution =>
      _execution ??= ExecutionClient(_dio, baseUrl: _baseUrl);

  FleetClient get fleet => _fleet ??= FleetClient(_dio, baseUrl: _baseUrl);

  FleetOpsClient get fleetOps =>
      _fleetOps ??= FleetOpsClient(_dio, baseUrl: _baseUrl);

  LabelsClient get labels => _labels ??= LabelsClient(_dio, baseUrl: _baseUrl);

  NetworkClient get network =>
      _network ??= NetworkClient(_dio, baseUrl: _baseUrl);

  NotificationsClient get notifications =>
      _notifications ??= NotificationsClient(_dio, baseUrl: _baseUrl);

  OutboxClient get outbox => _outbox ??= OutboxClient(_dio, baseUrl: _baseUrl);

  PlanningClient get planning =>
      _planning ??= PlanningClient(_dio, baseUrl: _baseUrl);

  SapConnectorClient get sapConnector =>
      _sapConnector ??= SapConnectorClient(_dio, baseUrl: _baseUrl);

  SettingsClient get settings =>
      _settings ??= SettingsClient(_dio, baseUrl: _baseUrl);

  ShipmentsClient get shipments =>
      _shipments ??= ShipmentsClient(_dio, baseUrl: _baseUrl);

  TrackingClient get tracking =>
      _tracking ??= TrackingClient(_dio, baseUrl: _baseUrl);

  PromiseClient get promise =>
      _promise ??= PromiseClient(_dio, baseUrl: _baseUrl);

  AccessClient get access => _access ??= AccessClient(_dio, baseUrl: _baseUrl);

  TelemetryClient get telemetry =>
      _telemetry ??= TelemetryClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  SellersClient get sellers =>
      _sellers ??= SellersClient(_dio, baseUrl: _baseUrl);

  InboundClient get inbound =>
      _inbound ??= InboundClient(_dio, baseUrl: _baseUrl);

  InventoryClient get inventory =>
      _inventory ??= InventoryClient(_dio, baseUrl: _baseUrl);

  SettlementClient get settlement =>
      _settlement ??= SettlementClient(_dio, baseUrl: _baseUrl);

  ReturnsClient get returns =>
      _returns ??= ReturnsClient(_dio, baseUrl: _baseUrl);

  SellerPortalClient get sellerPortal =>
      _sellerPortal ??= SellerPortalClient(_dio, baseUrl: _baseUrl);
}
