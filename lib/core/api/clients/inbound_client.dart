// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/announce_asn_request.dart';
import '../models/asn_collection.dart';
import '../models/asn_envelope.dart';
import '../models/asn_status.dart';
import '../models/label_received_units_request.dart';
import '../models/receiving_calendar_collection.dart';
import '../models/record_arrival_request.dart';
import '../models/record_goods_receipt_request.dart';
import '../models/schedule_asn_request.dart';

part 'inbound_client.g.dart';

@RestApi()
abstract class InboundClient {
  factory InboundClient(Dio dio, {String? baseUrl}) = _InboundClient;

  /// Announce an ASN.
  ///
  /// El seller anuncia un ASN (Advance Shipment Notice) declarando qué va a enviar. El id lo genera el.
  /// dominio; la respuesta es un acuse 202.
  @POST('/integrations/inbound/asn')
  Future<AcceptedEnvelope> announceAsn({
    @Body() required AnnounceAsnRequest body,
  });

  /// List ASNs
  @GET('/integrations/inbound/asn')
  Future<AsnCollection> listAsns({
    @Query('seller_id') String? sellerId,
    @Query('warehouse_id') String? warehouseId,
    @Query('status') AsnStatus? status,
    @Query('appointment_date') DateTime? appointmentDate,
  });

  /// Record the arrival of a seller's truck
  @POST('/integrations/inbound/asn/arrival')
  Future<AcceptedEnvelope> recordAsnArrival({
    @Body() required RecordArrivalRequest body,
  });

  /// Record a goods receipt with per-line QC
  @POST('/integrations/inbound/asn/receipt')
  Future<AcceptedEnvelope> recordGoodsReceipt({
    @Body() required RecordGoodsReceiptRequest body,
  });

  /// Label the accepted units of an ASN receipt
  @POST('/integrations/inbound/asn/label')
  Future<AcceptedEnvelope> labelReceivedUnits({
    @Body() required LabelReceivedUnitsRequest body,
  });

  /// Get an ASN
  @GET('/integrations/inbound/asn/{asnId}')
  Future<AsnEnvelope> getAsn({@Path('asnId') required String asnId});

  /// Schedule an ASN appointment.
  ///
  /// Agenda la ventana de cita del ASN y reserva el cupo de andén vía capacity. 202 de acuse.
  @PUT('/integrations/inbound/asn/{asnId}/schedule')
  Future<AcceptedEnvelope> scheduleAsn({
    @Path('asnId') required String asnId,
    @Body() required ScheduleAsnRequest body,
  });

  /// Receiving dock calendar.
  ///
  /// Devuelve el calendario de andén de recepción: por día y franja, cuántas citas hay agendadas.
  ///
  /// [from] - Start date (YYYY-MM-DD). Defaults to today.
  ///
  /// [days] - Number of days to return. Defaults to 7.
  @GET('/integrations/inbound/receiving-calendar')
  Future<ReceivingCalendarCollection> getReceivingCalendar({
    @Query('days') int? days = 7,
    @Query('from') DateTime? from,
    @Query('warehouse_id') String? warehouseId,
  });
}
