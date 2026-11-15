import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart' hide Type;
import '../../../core/api/models/type.dart' as api show Type;
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/null_body_strip_interceptor.dart';
import '../domain/entities/admin_vehicle.dart';
import '../domain/entities/maintenance_result.dart';
import '../../../core/widgets/paged.dart';

/// Única clase del feature Administración que habla con el backend
/// (`logisticsApiProvider`, cliente generado). Cada método espeja un endpoint,
/// devuelve el modelo del contrato y normaliza el error a [ApiException].
///
/// Las listas devuelven [Paged] (ítems + si quedan más páginas) para el
/// buscador con carga incremental de las pantallas.
class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._ref);

  final Ref _ref;

  /// Tamaño de página de las listas del administrador.
  static const int pageSize = 30;

  LogisticsApi get _api => _ref.read(logisticsApiProvider);

  // --- Camiones -------------------------------------------------------------

  /// Camiones de la flota. [query] busca por placa.
  Future<Paged<AdminVehicle>> listVehicles({
    String query = '',
    AdminVehicleStatus? status,
    int page = 1,
  }) => _guard(() async {
    final res = await _api.fleet.fleetListVehicles(
      page: page,
      perPage: pageSize,
      q: query.isEmpty ? null : query,
      status: status == null ? null : VehicleStatus.fromJson(status.wire),
    );
    final items = [
      for (final v in res.data ?? const <Vehicle>[])
        if (v.id != null)
          AdminVehicle(
            id: v.id!,
            plate: v.plate,
            status: AdminVehicleStatus.fromWire(v.status?.json),
            capacityKg: v.capacityKg,
            homeBaseNodeId: v.homeBaseNodeId,
            fitToDispatch: v.fitToDispatch,
            unfitReason: v.unfitReason,
          ),
    ];
    // Este endpoint no informa la página siguiente: una página completa puede
    // tener continuación (a lo sumo un GET vacío al final).
    return Paged(items: items, hasMore: (res.data?.length ?? 0) >= pageSize);
  });

  /// Manda el camión a mantenimiento AHORA: abre la orden y lo deja en
  /// mantenimiento en una sola llamada.
  Future<MaintenanceResult> sendToMaintenance(
    String vehicleId, {
    required MaintenanceType type,
    String? workshop,
    String? note,
    // Camión que toma las paradas PENDIENTES de su ruta. Sin él quedan
    // liberadas para asignarlas después.
    String? reassignToVehicleId,
  }) => _guard(() async {
    final res = await _api.fleet.fleetSendVehicleToMaintenance(
      vehicleId: vehicleId,
      body: AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody(
        type: api.Type.fromJson(type.wire),
        workshop: workshop == null || workshop.isEmpty ? null : workshop,
        note: note == null || note.isEmpty ? null : note,
        reassignToVehicleId: reassignToVehicleId,
      ),
    );
    final route = res.data?.route;
    return MaintenanceResult(
      reassignedCount: route?.reassigned?.length ?? 0,
      pendingOrders: [
        for (final order
            in route?.pendingReassignment ?? const <MaintenanceRouteOrder>[])
          order.orderReference ?? order.customerName ?? 'Pedido',
      ],
    );
  });

  /// Vehículos para elegir en un selector (asignar a un chofer / a un pedido).
  Future<List<AdminVehicle>> searchVehicles(String query) async =>
      (await listVehicles(query: query)).items;

  // --- Envíos ---------------------------------------------------------------

  /// Envíos de toda la operación. [query] busca por código de pedido, nombre o
  /// documento del cliente; [city] por ciudad de destino.
  Future<Paged<Shipment>> listShipments({
    String query = '',
    String city = '',
    ShipmentStatus? status,
    int page = 1,
  }) => _guard(() async {
    final res = await _api.shipments.listShipments(
      page: page,
      perPage: pageSize,
      q: query.isEmpty ? null : query,
      city: city.isEmpty ? null : city,
      status: status == null ? null : [status],
    );
    return Paged(items: res.data, hasMore: _hasMore(res.meta));
  });

  /// Vista previa de una reprogramación: cuántos y cuáles pedidos, sin aplicar.
  Future<RescheduleShipmentsResult> previewReschedule(
    RescheduleShipmentsRequest request,
  ) => _guard(
    () async =>
        (await _api.shipments.previewRescheduleShipments(body: request)).data,
  );

  /// Aplica la reprogramación.
  Future<RescheduleShipmentsResult> reschedule(
    RescheduleShipmentsRequest request,
  ) => _guard(
    () async => (await _api.shipments.rescheduleShipments(body: request)).data,
  );

  // --- Personal -------------------------------------------------------------

  /// Personal de la app (todos los roles). [query] busca por nombre o correo.
  Future<Paged<StaffMember>> listStaff({
    String query = '',
    Role? role,
    String? nodeId,
    Department? city,
    bool withoutCity = false,
    int page = 1,
  }) => _guard(() async {
    final res = await _api.staff.listStaff(
      page: page,
      perPage: pageSize,
      q: query.isEmpty ? null : query,
      role: role,
      nodeId: nodeId,
      city: withoutCity ? null : city,
      withoutCity: withoutCity ? true : null,
    );
    return Paged(items: res.data, hasMore: _hasMore(res.meta));
  });

  /// Ficha completa de una persona.
  Future<StaffProfile> getStaff(int userId) => _guard(
    () async => (await _api.staff.getStaffMember(userId: userId)).data,
  );

  Future<Paged<StaffDocument>> listStaffDocuments(int userId, int page) =>
      _guard(() async {
        final res = await _api.staff.listStaffDocuments(
          userId: userId,
          page: page,
          perPage: pageSize,
        );
        return Paged(items: res.data, hasMore: _hasMore(res.meta));
      });

  Future<Paged<StaffActivity>> listStaffActivity(int userId, int page) =>
      _guard(() async {
        final res = await _api.staff.listStaffActivity(
          userId: userId,
          page: page,
          perPage: pageSize,
        );
        return Paged(items: res.data, hasMore: _hasMore(res.meta));
      });

  Future<Paged<StaffPhoto>> listStaffPhotos(int userId, int page) =>
      _guard(() async {
        // El backend solo devuelve la foto de perfil y los documentos de la
        // persona: la evidencia de entregas es del pedido (dato del cliente).
        final res = await _api.staff.listStaffPhotos(
          userId: userId,
          page: page,
          perPage: pageSize,
        );
        return Paged(items: res.data, hasMore: _hasMore(res.meta));
      });

  /// Sube un documento (o foto) a la ficha de la persona.
  Future<StaffDocument> uploadStaffDocument(
    int userId, {
    required String documentType,
    required File file,
    DateTime? expiresOn,
    String? reference,
    StaffDocumentSide? side,
  }) => _guard(
    () async => (await _api.staff.uploadStaffDocument(
      userId: userId,
      documentType: documentType,
      file: file,
      expiresOn: expiresOn,
      reference: reference == null || reference.isEmpty ? null : reference,
      side: side,
    )).data,
  );

  /// Cuántos pedidos tiene HOY este camión sin terminar (asignados o ya
  /// cargados). Hasta una página: alcanza para saber si hay que reasignar.
  Future<int> pendingOrdersOf(String vehicleId) => _guard(() async {
    final res = await _api.shipments.listShipments(
      page: 1,
      perPage: pageSize,
      vehicleId: vehicleId,
      status: const [ShipmentStatus.planned, ShipmentStatus.inExecution],
    );
    return res.data.length;
  });

  /// Guarda los datos personales del formulario (cualquier rol). El backend
  /// solo cambia lo que viene en el cuerpo y un `null` BORRA el campo: por eso
  /// va por Dio directo con SOLO los campos del formulario (el cuerpo generado
  /// manda todas las claves y la fecha como fecha-hora).
  /// [changeCity] en `false` no toca la ciudad (la define la tienda asignada).
  Future<void> updateStaffProfile(
    int userId, {
    required String? phone,
    required String? phoneSecondary,
    required DateTime? birthDate,
    required String? nationalId,
    required String? address,
    required String? emergencyContactName,
    required String? emergencyContactPhone,
    Department? city,
    bool changeCity = false,
  }) => _guard(() async {
    await _ref
        .read(dioProvider)
        .put<Object?>(
          '/app/staff/$userId/profile',
          data: <String, Object?>{
            'phone': phone,
            'phone_secondary': phoneSecondary,
            // Fecha de calendario (`Y-m-d`), sin hora ni zona.
            'birth_date': birthDate == null
                ? null
                : '${birthDate.year.toString().padLeft(4, '0')}-'
                      '${birthDate.month.toString().padLeft(2, '0')}-'
                      '${birthDate.day.toString().padLeft(2, '0')}',
            'national_id': nationalId,
            'address': address,
            'emergency_contact_name': emergencyContactName,
            'emergency_contact_phone': emergencyContactPhone,
            if (changeCity) 'city': city?.json,
          },
          // Acá un `null` es "borrar el campo": que no lo quite el
          // interceptor que limpia los nulos del cuerpo.
          options: Options(
            extra: const {NullBodyStripInterceptor.keepNullsKey: true},
          ),
        );
  });

  /// Sube la foto de perfil de la persona.
  Future<void> uploadStaffPhoto(int userId, File photo) => _guard(() async {
    await _api.staff.uploadStaffPhoto(userId: userId, photo: photo);
  });

  /// Asigna la persona a una tienda/nodo ([nodeId] `null` = sin tienda).
  Future<StaffProfile> assignStaffNode(int userId, String? nodeId) => _guard(
    () async => (await _api.staff.assignStaffNode(
      userId: userId,
      body: AppStaffUserIdNodeRequestBody(nodeId: nodeId),
    )).data,
  );

  /// Tiendas y centros activos (para asignar personal).
  Future<List<Node>> listNodes() => _guard(
    () async =>
        (await _api.network.listNetworkNodes(status: NodeStatus.active)).data,
  );

  /// Asigna un camión a un chofer para [date] (arma su tripulación del día).
  Future<void> assignVehicle({
    required String driverId,
    required String vehicleId,
    required DateTime date,
  }) => _guard(() async {
    await _api.fleet.fleetAssembleCrew(
      body: AssembleCrewRequest(
        driverId: driverId,
        vehicleId: vehicleId,
        assembledFor: date,
      ),
    );
  });

  /// Quita la asignación vigente (tripulación) de un chofer.
  Future<void> removeCrew(String crewId) => _guard(() async {
    await _api.fleet.fleetDeleteCrew(crewId: crewId);
  });

  // --- Calendario de entregas ----------------------------------------------

  /// Días del calendario de entregas entre [from] y [to] (máx. 62 días).
  Future<List<Days>> getCalendar(DateTime from, DateTime to) => _guard(
    () async =>
        (await _api.capacity.getDeliveryCalendar(
          from: from,
          to: to,
        )).data?.days ??
        const <Days>[],
  );

  /// Bloquea un día para entregas (global).
  Future<void> blockDay(DateTime date, String reason) => _guard(() async {
    await _api.capacity.blockDeliveryDay(
      body: AppDeliveryCalendarBlockedRequestBody(date: date, reason: reason),
    );
  });

  /// Abre fechas de envío entre [from] y [to] con los cupos por defecto de
  /// las reglas (todos los municipios). Los cupos se generan en segundo plano.
  Future<void> openDays(DateTime from, DateTime to) => _guard(() async {
    await _api.capacity.openDeliverySlotsWithDefaults(
      body: OpenDeliverySlotsWithDefaultsRequest(from: from, to: to),
    );
  });

  /// Quita el bloqueo de un día.
  Future<void> unblockDay(DateTime date) => _guard(() async {
    await _api.capacity.unblockDeliveryDay(
      body: AppDeliveryCalendarBlockedRequestBody2(date: date),
    );
  });

  // --- Avisos al personal ---------------------------------------------------

  /// Envía un aviso interno. Devuelve a cuántas personas llegó.
  Future<int> sendBroadcast({
    required String title,
    required String body,
    StaffRoleName? role,
    String? nodeId,
    List<int>? userIds,
  }) => _guard(() async {
    // Dio directo: el cuerpo generado manda SIEMPRE `user_ids` (vacío si el
    // aviso va a un rol o a una tienda) y el backend lo rechaza con "debe
    // tener al menos 1 elemento". Acá viaja solo la audiencia elegida.
    final res = await _ref
        .read(dioProvider)
        .post<Map<String, Object?>>(
          '/app/broadcasts',
          data: <String, Object?>{
            'audience': <String, Object?>{
              if (role != null) 'role': role.json,
              'node_id': ?nodeId,
              if (userIds != null && userIds.isNotEmpty) 'user_ids': userIds,
            },
            'title': title,
            'body': body,
          },
        );
    final data = res.data?['data'];
    final count = data is Map ? data['recipient_count'] : null;
    return count is num ? count.toInt() : 0;
  });

  /// Avisos ya enviados (más recientes primero).
  Future<Paged<StaffBroadcast>> listBroadcasts(int page) => _guard(() async {
    final res = await _api.staff.listStaffBroadcasts(
      page: page,
      perPage: pageSize,
    );
    return Paged(items: res.data, hasMore: _hasMore(res.meta));
  });

  // --------------------------------------------------------------------------

  static bool _hasMore(ListMeta? meta) =>
      meta != null && (meta.nextPage != null || (meta.hasMore ?? false));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  AdminRemoteDataSource.new,
);
