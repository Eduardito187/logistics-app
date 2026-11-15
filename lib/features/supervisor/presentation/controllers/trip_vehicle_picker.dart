import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/widgets/staff_pickers.dart';

/// Camión elegido para un viaje.
typedef TripVehicle = ({String id, String plate});

/// Abre el selector de camiones (busca por placa). Seam para tests.
typedef TripVehiclePicker = Future<TripVehicle?> Function(BuildContext context);

final tripVehiclePickerProvider = Provider<TripVehiclePicker>(
  (ref) => (context) async {
    final vehicle = await showVehiclePickerSheet(context);
    return vehicle == null
        ? null
        : (id: vehicle.id, plate: vehicle.displayPlate);
  },
);
