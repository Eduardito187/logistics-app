import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Vehículos de la flota (`/app/fleet/vehicles`) para asignar al pedido en el
/// andén. Fuente única de verdad: así la asignación se LIMITA a camiones que
/// existen en vez de texto libre (escribir cualquier placa rompía el flujo:
/// el tracking iba a un camión inexistente).
///
/// autoDispose: se recarga cada vez que se abre el selector (la flota puede
/// cambiar de estado). Propaga [ApiException] para que la UI muestre el error.
final availableVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((
  ref,
) async {
  final api = ref.read(logisticsApiProvider);
  try {
    final res = await api.fleet.fleetListVehicles();
    final all = res.data ?? const <Vehicle>[];
    // Solo los que tienen placa, ordenados por placa (lista estable y buscable).
    return all.where((v) => (v.plate ?? '').trim().isNotEmpty).toList()
      ..sort((a, b) => (a.plate ?? '').compareTo(b.plate ?? ''));
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});
