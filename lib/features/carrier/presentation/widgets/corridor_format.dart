import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/vehicle_class.dart';

/// Etiqueta en español para el tipo de corredor.
String corridorTypeLabel(CorridorType type) => switch (type) {
  CorridorType.cdToCustomer => 'CD → Cliente',
  CorridorType.cdToCd => 'CD → CD',
  CorridorType.cdToStore => 'CD → Tienda',
  CorridorType.storeToStore => 'Tienda → Tienda',
  CorridorType.storeToCd => 'Tienda → CD',
  CorridorType.storePickup => 'Recojo en tienda',
  CorridorType.$unknown => 'Desconocido',
};

/// Etiqueta en español para la clase de vehículo.
String vehicleClassLabel(VehicleClass vClass) => switch (vClass) {
  VehicleClass.trailer => 'Tráiler',
  VehicleClass.truck => 'Camión',
  VehicleClass.thirdParty => 'Tercero',
  VehicleClass.$unknown => 'Desconocido',
};
