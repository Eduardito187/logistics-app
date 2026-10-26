// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/draft_seller_settlement_request.dart';
import '../models/seller_settlement_collection.dart';
import '../models/seller_settlement_envelope.dart';
import '../models/seller_settlement_mark_paid_request.dart';
import '../models/seller_settlement_status.dart';

part 'settlement_client.g.dart';

@RestApi()
abstract class SettlementClient {
  factory SettlementClient(Dio dio, {String? baseUrl}) = _SettlementClient;

  /// List seller settlements
  @GET('/integrations/settlements')
  Future<SellerSettlementCollection> listSellerSettlements({
    @Query('seller_id') String? sellerId,
    @Query('status') SellerSettlementStatus? status,
    @Query('period_from') DateTime? periodFrom,
    @Query('period_to') DateTime? periodTo,
  });

  /// Draft a seller settlement.
  ///
  /// Arma el borrador de una liquidación de seller agregando sus despachos del periodo. Los términos.
  /// (comisión/fee) llegan en el cuerpo porque settlement no depende del contexto sellers. 202 de acuse.
  @POST('/integrations/settlements/draft')
  Future<AcceptedEnvelope> draftSellerSettlement({
    @Body() required DraftSellerSettlementRequest body,
  });

  /// Get a seller settlement
  @GET('/integrations/settlements/{settlementId}')
  Future<SellerSettlementEnvelope> getSellerSettlement({
    @Path('settlementId') required String settlementId,
  });

  /// Confirm a draft seller settlement
  @POST('/integrations/settlements/{settlementId}/confirm')
  Future<AcceptedEnvelope> confirmSellerSettlement({
    @Path('settlementId') required String settlementId,
  });

  /// Mark a seller settlement as paid
  @POST('/integrations/settlements/{settlementId}/pay')
  Future<AcceptedEnvelope> paySellerSettlement({
    @Path('settlementId') required String settlementId,
    @Body() required SellerSettlementMarkPaidRequest body,
  });
}
