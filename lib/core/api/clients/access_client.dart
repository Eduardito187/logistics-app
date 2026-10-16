// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/app_access_permissions_request_body.dart';
import '../models/app_access_roles_request_body.dart';
import '../models/app_access_roles_role_id_permissions_grant_request_body.dart';
import '../models/app_access_roles_role_id_permissions_request_body.dart';
import '../models/app_access_roles_role_id_permissions_revoke_request_body.dart';
import '../models/app_access_roles_role_id_request_body.dart';
import '../models/app_access_tokens_request_body.dart';
import '../models/app_access_tokens_token_id_permissions_request_body.dart';
import '../models/app_access_users_request_body.dart';
import '../models/app_access_users_user_id_password_request_body.dart';
import '../models/app_access_users_user_id_roles_request_body.dart';
import '../models/get_app_access_permissions_response.dart';
import '../models/get_app_access_roles_response.dart';
import '../models/get_app_access_roles_role_id_response.dart';
import '../models/get_app_access_tokens_response.dart';
import '../models/get_app_access_tokens_token_id_response.dart';
import '../models/get_app_access_users_response.dart';
import '../models/get_app_access_users_user_id_response.dart';
import '../models/get_integrations_access_token_verify_response.dart';
import '../models/post_app_access_tokens_response.dart';
import '../models/post_app_access_tokens_token_id_rotate_response.dart';
import '../models/status5.dart';
import '../models/status6.dart';

part 'access_client.g.dart';

@RestApi()
abstract class AccessClient {
  factory AccessClient(Dio dio, {String? baseUrl}) = _AccessClient;

  /// List permissions
  @GET('/app/access/permissions')
  Future<GetAppAccessPermissionsResponse> listPermissions({
    @Query('group') String? group,
  });

  /// Register a permission
  @POST('/app/access/permissions')
  Future<AcceptedEnvelope> registerPermission({
    @Body() required AppAccessPermissionsRequestBody body,
  });

  /// List roles
  @GET('/app/access/roles')
  Future<GetAppAccessRolesResponse> listRoles();

  /// Define a role
  @POST('/app/access/roles')
  Future<AcceptedEnvelope> defineRole({
    @Body() required AppAccessRolesRequestBody body,
  });

  /// Get a role
  @GET('/app/access/roles/{roleId}')
  Future<GetAppAccessRolesRoleIdResponse> getRole({
    @Path('roleId') required String roleId,
  });

  /// Rename a role
  @PATCH('/app/access/roles/{roleId}')
  Future<AcceptedEnvelope> renameRole({
    @Path('roleId') required String roleId,
    @Body() required AppAccessRolesRoleIdRequestBody body,
  });

  /// Delete a role
  @DELETE('/app/access/roles/{roleId}')
  Future<AcceptedEnvelope> deleteRole({@Path('roleId') required String roleId});

  /// Replace the full permission set of a role
  @PUT('/app/access/roles/{roleId}/permissions')
  Future<AcceptedEnvelope> setRolePermissions({
    @Path('roleId') required String roleId,
    @Body() required AppAccessRolesRoleIdPermissionsRequestBody body,
  });

  /// Grant a permission to a role
  @POST('/app/access/roles/{roleId}/permissions/grant')
  Future<AcceptedEnvelope> grantPermissionToRole({
    @Path('roleId') required String roleId,
    @Body() required AppAccessRolesRoleIdPermissionsGrantRequestBody body,
  });

  /// Revoke a permission from a role
  @POST('/app/access/roles/{roleId}/permissions/revoke')
  Future<AcceptedEnvelope> revokePermissionFromRole({
    @Path('roleId') required String roleId,
    @Body() required AppAccessRolesRoleIdPermissionsRevokeRequestBody body,
  });

  /// List users
  @GET('/app/access/users')
  Future<GetAppAccessUsersResponse> listUsers({
    @Query('status') Status5? status,
  });

  /// Register a user
  @POST('/app/access/users')
  Future<AcceptedEnvelope> registerUser({
    @Body() required AppAccessUsersRequestBody body,
  });

  /// Get a user
  @GET('/app/access/users/{userId}')
  Future<GetAppAccessUsersUserIdResponse> getUser({
    @Path('userId') required String userId,
  });

  /// Suspend a user
  @POST('/app/access/users/{userId}/suspend')
  Future<AcceptedEnvelope> suspendUser({
    @Path('userId') required String userId,
  });

  /// Reactivate a user
  @POST('/app/access/users/{userId}/reactivate')
  Future<AcceptedEnvelope> reactivateUser({
    @Path('userId') required String userId,
  });

  /// Change a user password
  @POST('/app/access/users/{userId}/password')
  Future<AcceptedEnvelope> changeUserPassword({
    @Path('userId') required String userId,
    @Body() required AppAccessUsersUserIdPasswordRequestBody body,
  });

  /// Assign a role to a user
  @POST('/app/access/users/{userId}/roles')
  Future<AcceptedEnvelope> assignRoleToUser({
    @Path('userId') required String userId,
    @Body() required AppAccessUsersUserIdRolesRequestBody body,
  });

  /// Remove a role from a user
  @DELETE('/app/access/users/{userId}/roles/{roleKey}')
  Future<AcceptedEnvelope> removeRoleFromUser({
    @Path('userId') required String userId,
    @Path('roleKey') required String roleKey,
  });

  /// List integration tokens
  @GET('/app/access/tokens')
  Future<GetAppAccessTokensResponse> listIntegrationTokens({
    @Query('status') Status6? status,
  });

  /// Issue an integration token.
  ///
  /// Emite un token nuevo y devuelve el secreto en claro (plain_token) UNA sola vez; después no se recupera.
  @POST('/app/access/tokens')
  Future<PostAppAccessTokensResponse> issueIntegrationToken({
    @Body() required AppAccessTokensRequestBody body,
  });

  /// Get an integration token
  @GET('/app/access/tokens/{tokenId}')
  Future<GetAppAccessTokensTokenIdResponse> getIntegrationToken({
    @Path('tokenId') required String tokenId,
  });

  /// Rotate an integration token secret.
  ///
  /// Rota el secreto de un token activo y devuelve el valor en claro nuevo UNA sola vez.
  @POST('/app/access/tokens/{tokenId}/rotate')
  Future<PostAppAccessTokensTokenIdRotateResponse> rotateIntegrationToken({
    @Path('tokenId') required String tokenId,
  });

  /// Revoke an integration token
  @POST('/app/access/tokens/{tokenId}/revoke')
  Future<AcceptedEnvelope> revokeIntegrationToken({
    @Path('tokenId') required String tokenId,
  });

  /// Replace the full permission set of an integration token
  @PUT('/app/access/tokens/{tokenId}/permissions')
  Future<AcceptedEnvelope> setTokenPermissions({
    @Path('tokenId') required String tokenId,
    @Body() required AppAccessTokensTokenIdPermissionsRequestBody body,
  });

  /// Verify the presented integration token.
  ///
  /// El integrador valida su propia credencial. El middleware access.token autentica el Bearer y.
  /// devuelve el id del token y sus permisos efectivos. La puerta integrations también aplica.
  /// serviceCredential, de modo que ambas credenciales viajan en la petición.
  @GET('/integrations/access/token/verify')
  Future<GetIntegrationsAccessTokenVerifyResponse> verifyIntegrationToken();
}
