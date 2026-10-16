import '../../../core/api/export.dart';

/// Etiqueta en español del tipo de combustible.
String fuelTypeLabel(FuelType type) => switch (type) {
  FuelType.gasolineSpecial => 'Gasolina especial',
  FuelType.gasolinePremium => 'Gasolina premium',
  FuelType.diesel => 'Diésel',
  FuelType.gnv => 'GNV',
  _ => 'Combustible',
};

/// Etiqueta en español del tipo de servicio de mantenimiento.
String serviceKindLabel(MaintenancePlanServiceKind? kind) => switch (kind) {
  MaintenancePlanServiceKind.oilChange => 'Cambio de aceite',
  MaintenancePlanServiceKind.tires => 'Llantas',
  MaintenancePlanServiceKind.brakes => 'Frenos',
  MaintenancePlanServiceKind.filters => 'Filtros',
  MaintenancePlanServiceKind.battery => 'Batería',
  MaintenancePlanServiceKind.general => 'Servicio general',
  MaintenancePlanServiceKind.inspection => 'Inspección',
  _ => 'Mantenimiento',
};
