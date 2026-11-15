// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/app_broadcasts_request_body.dart';
import '../models/app_staff_user_id_node_request_body.dart';
import '../models/app_staff_user_id_profile_request_body.dart';
import '../models/get_app_broadcasts_response.dart';
import '../models/get_app_inbox_response.dart';
import '../models/get_app_staff_response.dart';
import '../models/get_app_staff_user_id_activity_response.dart';
import '../models/get_app_staff_user_id_documents_response.dart';
import '../models/get_app_staff_user_id_photos_response.dart';
import '../models/get_app_staff_user_id_response.dart';
import '../models/post_app_broadcasts_response.dart';
import '../models/post_app_inbox_read_all_response.dart';
import '../models/post_app_staff_user_id_documents_response.dart';
import '../models/post_app_staff_user_id_photo_response.dart';
import '../models/put_app_staff_user_id_node_response.dart';
import '../models/put_app_staff_user_id_profile_response.dart';
import '../models/role.dart';
import '../models/type3.dart';

part 'staff_client.g.dart';

@RestApi()
abstract class StaffClient {
  factory StaffClient(Dio dio, {String? baseUrl}) = _StaffClient;

  /// Staff directory (any role) with search, role and store filters.
  ///
  /// Solo admin y supervisor. El personal de la app son los usuarios de `users` (id entero); /app/access/users es el módulo de cuentas administrativas.
  ///
  /// [q] - Búsqueda por nombre o email.
  ///
  /// [nodeId] - Solo el personal asignado a esa tienda / nodo.
  ///
  /// [withoutNode] - true = solo personal sin tienda asignada.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/staff')
  Future<GetAppStaffResponse> listStaff({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('q') String? q,
    @Query('role') Role? role,
    @Query('node_id') String? nodeId,
    @Query('without_node') bool? withoutNode,
    @Query('cursor') String? cursor,
  });

  /// Staff member profile (one view for every role).
  ///
  /// [userId] - Id del usuario de la app (entero).
  @GET('/app/staff/{userId}')
  Future<GetAppStaffUserIdResponse> getStaffMember({
    @Path('userId') required int userId,
  });

  /// Documents of a staff member (uploaded to the profile + fleet documents if driver).
  ///
  /// [userId] - Id del usuario de la app (entero).
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/staff/{userId}/documents')
  Future<GetAppStaffUserIdDocumentsResponse> listStaffDocuments({
    @Path('userId') required int userId,
    @Query('cursor') String? cursor,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
  });

  /// Upload a document to the staff member profile.
  ///
  /// [userId] - Id del usuario de la app (entero).
  ///
  /// [documentType] - Tipo libre, p. ej. carnet_identidad, licencia, contrato.
  ///
  /// [file] - pdf, jpg, jpeg, png o webp; máx. 10 MB.
  @MultiPart()
  @POST('/app/staff/{userId}/documents')
  Future<PostAppStaffUserIdDocumentsResponse> uploadStaffDocument({
    @Path('userId') required int userId,
    @Part(name: 'document_type') required String documentType,
    @Part(name: 'file') required File file,
    @Part(name: 'reference') String? reference,
    @Part(name: 'issued_on') DateTime? issuedOn,
    @Part(name: 'expires_on') DateTime? expiresOn,
    @Part(name: 'note') String? note,
  });

  /// Activity history of a staff member, most recent first.
  ///
  /// [userId] - Id del usuario de la app (entero).
  ///
  /// [type] - scan = escaneos en terreno; assignment = vehículo asignado; checklist = inspección pre-salida; device = último uso de un dispositivo.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/staff/{userId}/activity')
  Future<GetAppStaffUserIdActivityResponse> listStaffActivity({
    @Path('userId') required int userId,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('type') Type3? type,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
    @Query('cursor') String? cursor,
  });

  /// Photos of a staff member (profile, document images, evidence captured).
  ///
  /// [userId] - Id del usuario de la app (entero).
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/staff/{userId}/photos')
  Future<GetAppStaffUserIdPhotosResponse> listStaffPhotos({
    @Path('userId') required int userId,
    @Query('cursor') String? cursor,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
  });

  /// Assign the staff member to a store / node (or remove it with null).
  ///
  /// [userId] - Id del usuario de la app (entero).
  @PUT('/app/staff/{userId}/node')
  Future<PutAppStaffUserIdNodeResponse> assignStaffNode({
    @Path('userId') required int userId,
    @Body() required AppStaffUserIdNodeRequestBody body,
  });

  /// Save personal data of a staff member (any role).
  ///
  /// Solo cambia lo que viene en el cuerpo; un campo en null lo borra.
  @PUT('/app/staff/{userId}/profile')
  Future<PutAppStaffUserIdProfileResponse> updateStaffProfile({
    @Path('userId') required int userId,
    @Body() required AppStaffUserIdProfileRequestBody body,
  });

  /// Upload the profile photo of a staff member (replaces the previous one).
  ///
  /// [photo] - Imagen, máx. 8 MB.
  @MultiPart()
  @POST('/app/staff/{userId}/photo')
  Future<PostAppStaffUserIdPhotoResponse> uploadStaffPhoto({
    @Path('userId') required int userId,
    @Part(name: 'photo') required File photo,
  });

  /// Internal notices sent to staff, with recipient and read counts.
  ///
  /// Admin y supervisor.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/broadcasts')
  Future<GetAppBroadcastsResponse> listStaffBroadcasts({
    @Query('cursor') String? cursor,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
  });

  /// Send an internal notice to a role, a store or specific users (admin only).
  ///
  /// El aviso queda al instante en la bandeja (/app/inbox) de cada destinatario; el push (FCM) sale después por la cola. Avisos al personal, no al cliente.
  @POST('/app/broadcasts')
  Future<PostAppBroadcastsResponse> sendStaffBroadcast({
    @Body() required AppBroadcastsRequestBody body,
  });

  /// Inbox of internal notices of the authenticated user (any role).
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/inbox')
  Future<GetAppInboxResponse> listInbox({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('unread') bool? unread,
    @Query('cursor') String? cursor,
  });

  /// Mark every notice of the inbox as read
  @POST('/app/inbox/read-all')
  Future<PostAppInboxReadAllResponse> markInboxAllRead();

  /// Mark one notice as read
  @POST('/app/inbox/{broadcastId}/read')
  Future<AcceptedEnvelope> markInboxRead({
    @Path('broadcastId') required String broadcastId,
  });
}
