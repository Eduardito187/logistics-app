import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/delivery_evidence.dart';

/// Lee las evidencias de entrega de un envío (con su estado de validación
/// anti-fraude) desde `GET /app/deliveries/{shipmentId}/evidence`. Dio crudo: el
/// cliente generado aún no tiene este endpoint.
class DeliveryEvidenceDataSource {
  const DeliveryEvidenceDataSource(this._dio);

  final Dio _dio;

  Future<List<DeliveryEvidenceItem>> get(String shipmentId) async {
    try {
      final res = await _dio.get<Map<String, Object?>>(
        '/app/deliveries/$shipmentId/evidence',
      );
      final data = (res.data?['data'] as List<Object?>?) ?? const [];
      return data
          .map(
            (e) => DeliveryEvidenceItem.fromJson(
              (e as Map).cast<String, Object?>(),
            ),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final deliveryEvidenceDataSourceProvider = Provider<DeliveryEvidenceDataSource>(
  (ref) => DeliveryEvidenceDataSource(ref.watch(dioProvider)),
);

/// Evidencias (firma/documento/fotos) de un envío con su estado de validación.
/// Autodispose + family por envío; se refresca al reabrir la hoja de detalle.
final deliveryEvidenceProvider = FutureProvider.autoDispose
    .family<List<DeliveryEvidenceItem>, String>((ref, shipmentId) {
      return ref.watch(deliveryEvidenceDataSourceProvider).get(shipmentId);
    });
