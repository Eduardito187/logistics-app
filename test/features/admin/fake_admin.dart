import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/widgets/paged.dart';
import 'package:logistics_app/features/admin/data/admin_remote_data_source.dart';
import 'package:logistics_app/features/admin/domain/entities/admin_vehicle.dart';

// Fuente de datos falsa del módulo de administración: datos en memoria y un
// registro de cada escritura, para verificar qué manda cada pantalla.

class FakeAdmin implements AdminRemoteDataSource {
  FakeAdmin({
    this.staff = const [],
    this.profile,
    this.vehicles = const [],
    this.nodes = const [],
    this.documents = const [],
    this.activity = const [],
    this.photos = const [],
    this.broadcasts = const [],
    this.calendar = const [],
    this.preview,
    this.error,
  });

  List<StaffMember> staff;
  StaffProfile? profile;
  List<AdminVehicle> vehicles;
  List<Node> nodes;
  List<StaffDocument> documents;
  List<StaffActivity> activity;
  List<StaffPhoto> photos;
  List<StaffBroadcast> broadcasts;
  List<Days> calendar;
  RescheduleShipmentsResult? preview;

  /// Si se setea, las lecturas y escrituras fallan con este error.
  Object? error;

  // Registro de escrituras.
  final List<({String query, Role? role})> staffRequests = [];
  final List<({int userId, String? nodeId})> nodeAssignments = [];
  final List<({String driverId, String vehicleId})> vehicleAssignments = [];
  final List<String> removedCrews = [];
  final List<RescheduleShipmentsRequest> previews = [];
  final List<RescheduleShipmentsRequest> applied = [];
  final List<({DateTime date, String reason})> blocked = [];
  final List<DateTime> unblocked = [];
  final List<({DateTime from, DateTime to})> opened = [];
  final List<
    ({
      String title,
      String body,
      StaffRoleName? role,
      String? nodeId,
      List<int>? userIds,
    })
  >
  sent = [];
  final List<({int userId, String type, String path})> uploads = [];

  void _fail() {
    final e = error;
    if (e != null) throw e;
  }

  Paged<T> _all<T>(List<T> items) => Paged(items: items, hasMore: false);

  @override
  Future<Paged<StaffMember>> listStaff({
    String query = '',
    Role? role,
    String? nodeId,
    int page = 1,
  }) async {
    _fail();
    staffRequests.add((query: query, role: role));
    return _all([
      for (final m in staff)
        if ((role == null || m.roles.contains(role.json)) &&
            m.name.toLowerCase().contains(query.toLowerCase()))
          m,
    ]);
  }

  @override
  Future<StaffProfile> getStaff(int userId) async {
    _fail();
    return profile!;
  }

  @override
  Future<Paged<StaffDocument>> listStaffDocuments(int userId, int page) async =>
      _all(documents);

  @override
  Future<Paged<StaffActivity>> listStaffActivity(int userId, int page) async =>
      _all(activity);

  @override
  Future<Paged<StaffPhoto>> listStaffPhotos(int userId, int page) async =>
      _all(photos);

  @override
  Future<StaffDocument> uploadStaffDocument(
    int userId, {
    required String documentType,
    required File file,
    DateTime? expiresOn,
    String? reference,
  }) async {
    _fail();
    uploads.add((userId: userId, type: documentType, path: file.path));
    return StaffDocument(id: 'doc-new', documentType: documentType);
  }

  @override
  Future<StaffProfile> assignStaffNode(int userId, String? nodeId) async {
    _fail();
    nodeAssignments.add((userId: userId, nodeId: nodeId));
    return profile!;
  }

  @override
  Future<List<Node>> listNodes() async => nodes;

  @override
  Future<Paged<AdminVehicle>> listVehicles({
    String query = '',
    AdminVehicleStatus? status,
    int page = 1,
  }) async => _all([
    for (final v in vehicles)
      if (v.displayPlate.toLowerCase().contains(query.toLowerCase())) v,
  ]);

  @override
  Future<void> assignVehicle({
    required String driverId,
    required String vehicleId,
    required DateTime date,
  }) async {
    _fail();
    vehicleAssignments.add((driverId: driverId, vehicleId: vehicleId));
  }

  @override
  Future<void> removeCrew(String crewId) async {
    _fail();
    removedCrews.add(crewId);
  }

  @override
  Future<RescheduleShipmentsResult> previewReschedule(
    RescheduleShipmentsRequest request,
  ) async {
    _fail();
    previews.add(request);
    return preview!;
  }

  @override
  Future<RescheduleShipmentsResult> reschedule(
    RescheduleShipmentsRequest request,
  ) async {
    _fail();
    applied.add(request);
    return RescheduleShipmentsResult(
      applied: true,
      count: preview?.count,
      newDate: request.newDate,
    );
  }

  @override
  Future<List<Days>> getCalendar(DateTime from, DateTime to) async {
    _fail();
    return calendar;
  }

  @override
  Future<void> blockDay(DateTime date, String reason) async {
    _fail();
    blocked.add((date: date, reason: reason));
  }

  @override
  Future<void> openDays(DateTime from, DateTime to) async {
    _fail();
    opened.add((from: from, to: to));
  }

  @override
  Future<void> unblockDay(DateTime date) async {
    _fail();
    unblocked.add(date);
  }

  @override
  Future<int> sendBroadcast({
    required String title,
    required String body,
    StaffRoleName? role,
    String? nodeId,
    List<int>? userIds,
  }) async {
    _fail();
    sent.add((
      title: title,
      body: body,
      role: role,
      nodeId: nodeId,
      userIds: userIds,
    ));
    return 12;
  }

  @override
  Future<Paged<StaffBroadcast>> listBroadcasts(int page) async =>
      _all(broadcasts);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Monta [screen] con la fuente de datos falsa, en una superficie alta (las
/// listas son perezosas y los formularios largos).
Future<void> pumpAdmin(
  WidgetTester tester,
  FakeAdmin fake,
  Widget screen, {
  List<Object> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminRemoteDataSourceProvider.overrideWithValue(fake),
        ...overrides,
      ].cast(),
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

Node adminNode({String id = 'node-1', String name = 'Tienda Norte'}) => Node(
  id: id,
  code: 'T-01',
  name: name,
  type: NodeType.store,
  lat: -17.7,
  lng: -63.1,
  status: NodeStatus.active,
);
