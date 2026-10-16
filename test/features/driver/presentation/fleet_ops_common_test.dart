import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/fleet_ops_common.dart';

// Etiquetas en español de tipo de combustible y de servicio de mantenimiento.

void main() {
  group('fuelTypeLabel', () {
    test('cubre los tipos definidos', () {
      expect(fuelTypeLabel(FuelType.gasolineSpecial), 'Gasolina especial');
      expect(fuelTypeLabel(FuelType.gasolinePremium), 'Gasolina premium');
      expect(fuelTypeLabel(FuelType.diesel), 'Diésel');
      expect(fuelTypeLabel(FuelType.gnv), 'GNV');
    });

    test('tipo desconocido cae en "Combustible"', () {
      expect(fuelTypeLabel(FuelType.$unknown), 'Combustible');
    });
  });

  group('serviceKindLabel', () {
    test('cubre los tipos de servicio definidos', () {
      expect(
        serviceKindLabel(MaintenancePlanServiceKind.oilChange),
        'Cambio de aceite',
      );
      expect(serviceKindLabel(MaintenancePlanServiceKind.tires), 'Llantas');
      expect(serviceKindLabel(MaintenancePlanServiceKind.brakes), 'Frenos');
      expect(serviceKindLabel(MaintenancePlanServiceKind.filters), 'Filtros');
      expect(serviceKindLabel(MaintenancePlanServiceKind.battery), 'Batería');
      expect(
        serviceKindLabel(MaintenancePlanServiceKind.general),
        'Servicio general',
      );
      expect(
        serviceKindLabel(MaintenancePlanServiceKind.inspection),
        'Inspección',
      );
    });

    test('null o desconocido cae en "Mantenimiento"', () {
      expect(serviceKindLabel(null), 'Mantenimiento');
      expect(
        serviceKindLabel(MaintenancePlanServiceKind.$unknown),
        'Mantenimiento',
      );
    });
  });
}
