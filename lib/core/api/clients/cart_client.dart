// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/commerce_add_item_request.dart';
import '../models/commerce_cart_response.dart';
import '../models/commerce_open_cart_request.dart';
import '../models/commerce_update_item_qty_request.dart';

part 'cart_client.g.dart';

@RestApi()
abstract class CartClient {
  factory CartClient(Dio dio, {String? baseUrl}) = _CartClient;

  /// Open a cart for a session/customer
  @POST('/channels/cart')
  Future<CommerceCartResponse> openCart({
    @Body() required CommerceOpenCartRequest body,
  });

  /// Get a cart by id.
  ///
  /// [cart] - Cart id.
  @GET('/channels/cart/{cart}')
  Future<CommerceCartResponse> getCart({@Path('cart') required String cart});

  /// Add an item to the cart.
  ///
  /// [cart] - Cart id.
  @POST('/channels/cart/{cart}/items')
  Future<CommerceCartResponse> addCartItem({
    @Path('cart') required String cart,
    @Body() required CommerceAddItemRequest body,
  });

  /// Update the quantity of a cart line (0 removes it).
  ///
  /// [cart] - Cart id.
  ///
  /// [sku] - Line SKU within the cart.
  @PATCH('/channels/cart/{cart}/items/{sku}')
  Future<CommerceCartResponse> updateCartItemQty({
    @Path('cart') required String cart,
    @Path('sku') required String sku,
    @Body() required CommerceUpdateItemQtyRequest body,
  });

  /// Remove a line from the cart.
  ///
  /// [cart] - Cart id.
  ///
  /// [sku] - Line SKU within the cart.
  @DELETE('/channels/cart/{cart}/items/{sku}')
  Future<CommerceCartResponse> removeCartItem({
    @Path('cart') required String cart,
    @Path('sku') required String sku,
  });
}
