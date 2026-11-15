// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/commerce_add_address_request.dart';
import '../models/commerce_register_account_request.dart';
import '../models/delete_channels_accounts_account_addresses_address_response.dart';
import '../models/get_channels_accounts_account_response.dart';
import '../models/get_channels_accounts_by_user_user_id_response.dart';
import '../models/post_channels_accounts_account_addresses_response.dart';
import '../models/post_channels_accounts_response.dart';

part 'accounts_client.g.dart';

@RestApi()
abstract class AccountsClient {
  factory AccountsClient(Dio dio, {String? baseUrl}) = _AccountsClient;

  /// Register a customer account
  @POST('/channels/accounts')
  Future<PostChannelsAccountsResponse> registerAccount({
    @Body() required CommerceRegisterAccountRequest body,
  });

  /// Get the account of a user
  @GET('/channels/accounts/by-user/{userId}')
  Future<GetChannelsAccountsByUserUserIdResponse> getAccountByUser({
    @Path('userId') required String userId,
  });

  /// Get an account by id.
  ///
  /// [account] - Account id.
  @GET('/channels/accounts/{account}')
  Future<GetChannelsAccountsAccountResponse> getAccount({
    @Path('account') required String account,
  });

  /// Add an address to an account.
  ///
  /// [account] - Account id.
  @POST('/channels/accounts/{account}/addresses')
  Future<PostChannelsAccountsAccountAddressesResponse> addAccountAddress({
    @Path('account') required String account,
    @Body() required CommerceAddAddressRequest body,
  });

  /// Remove an address from an account (identified by its label).
  ///
  /// [account] - Account id.
  ///
  /// [address] - The address label (the VO Address has no id).
  @DELETE('/channels/accounts/{account}/addresses/{address}')
  Future<DeleteChannelsAccountsAccountAddressesAddressResponse>
  removeAccountAddress({
    @Path('account') required String account,
    @Path('address') required String address,
  });
}
