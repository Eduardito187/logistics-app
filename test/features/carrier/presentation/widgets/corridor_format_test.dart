import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/vehicle_class.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/corridor_format.dart';

// Etiquetas en español para tipo de corredor y clase de vehículo, incluyendo el
// valor desconocido (compatibilidad hacia adelante).

void main() {
  group('corridorTypeLabel', () {
    test('traduce cada tipo de corredor', () {
      expect(corridorTypeLabel(CorridorType.cdToCustomer), 'CD → Cliente');
      expect(corridorTypeLabel(CorridorType.cdToCd), 'CD → CD');
      expect(corridorTypeLabel(CorridorType.cdToStore), 'CD → Tienda');
      expect(corridorTypeLabel(CorridorType.storeToStore), 'Tienda → Tienda');
      expect(corridorTypeLabel(CorridorType.storeToCd), 'Tienda → CD');
      expect(corridorTypeLabel(CorridorType.storePickup), 'Recojo en tienda');
      expect(corridorTypeLabel(CorridorType.$unknown), 'Desconocido');
    });

    test('cubre todos los valores definidos del enum', () {
      for (final type in CorridorType.$valuesDefined) {
        expect(corridorTypeLabel(type), isNot('Desconocido'));
      }
    });
  });

  group('corridorNodeLabel', () {
    test('traduce el prefijo del nodo y capitaliza el resto', () {
      expect(corridorNodeLabel('cd-santa-cruz'), 'CD Santa Cruz');
      expect(corridorNodeLabel('cd-la-paz'), 'CD La Paz');
      expect(corridorNodeLabel('cd-cochabamba'), 'CD Cochabamba');
      expect(corridorNodeLabel('store-scz-centro'), 'Tienda SCZ Centro');
      expect(corridorNodeLabel('hub-el-alto'), 'Hub El Alto');
    });

    test('las siglas cortas quedan en mayúsculas', () {
      expect(corridorNodeLabel('LPB'), 'LPB');
      expect(corridorNodeLabel('scz'), 'SCZ');
      expect(corridorNodeLabel('store_cbb_norte'), 'Tienda CBB Norte');
    });

    test('tolera claves raras sin romperse', () {
      expect(corridorNodeLabel(''), '');
      expect(corridorNodeLabel('   '), '');
      expect(corridorNodeLabel('--'), '--');
      expect(corridorNodeLabel('CD-SCZ-01'), 'CD SCZ 01');
    });
  });

  group('corridorPairLabel', () {
    test('arma el par legible con la flecha', () {
      expect(
        corridorPairLabel('cd-santa-cruz', 'store-scz-centro'),
        'CD Santa Cruz → Tienda SCZ Centro',
      );
    });
  });

  group('vehicleClassLabel', () {
    test('traduce cada clase de vehículo', () {
      expect(vehicleClassLabel(VehicleClass.trailer), 'Tráiler');
      expect(vehicleClassLabel(VehicleClass.truck), 'Camión');
      expect(vehicleClassLabel(VehicleClass.thirdParty), 'Terceros');
      expect(vehicleClassLabel(VehicleClass.$unknown), 'Desconocido');
    });
  });
}
