import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/supervisor_controllers.dart';

/// "Camión 904U10": la placa del camión. Mientras cargan las placas, o si el
/// camión no tiene una, se muestra el id abreviado (nunca el UUID entero).
///
/// `select` por la placa de ESTE camión: cada tarjeta (plan, alerta, hoja) se
/// reconstruye solo si cambia su propia placa, no ante cualquier cambio del
/// mapa de placas (carga, error, recarga) de toda la flota.
String vehicleLabel(WidgetRef ref, String vehicleId) {
  final plate = ref.watch(
    vehiclePlatesProvider.select((plates) => plates.value?[vehicleId]),
  );
  return 'Camión ${plate ?? shortVehicleId(vehicleId)}';
}

/// Id de vehículo abreviado a sus últimos 6 caracteres (`…e6d47c`).
String shortVehicleId(String id) =>
    id.length <= 8 ? id : '…${id.substring(id.length - 6)}';
