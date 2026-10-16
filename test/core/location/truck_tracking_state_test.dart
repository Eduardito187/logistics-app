import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/gps_fix.dart';
import 'package:logistics_app/core/location/truck_tracking_state.dart';

// Estado observable del rastreo. Se cubren los valores por defecto y el
// comportamiento de copyWith (merge campo a campo).
void main() {
  group('TruckTrackingState', () {
    test('valores por defecto: inactivo, sin envío, 0 enviados, sin fix', () {
      const state = TruckTrackingState();
      expect(state.active, isFalse);
      expect(state.shipmentId, isNull);
      expect(state.sent, 0);
      expect(state.lastFix, isNull);
    });

    test('copyWith cambia solo los campos provistos', () {
      const state = TruckTrackingState();
      final next = state.copyWith(active: true, shipmentId: 'SHP-1', sent: 3);
      expect(next.active, isTrue);
      expect(next.shipmentId, 'SHP-1');
      expect(next.sent, 3);
      expect(next.lastFix, isNull);
    });

    test('copyWith sin argumentos conserva todos los campos', () {
      const fix = GpsFix(lat: 1, lng: 2, accuracy: 3);
      const state = TruckTrackingState(
        active: true,
        shipmentId: 'SHP-9',
        sent: 7,
        lastFix: fix,
      );
      final copy = state.copyWith();
      expect(copy.active, isTrue);
      expect(copy.shipmentId, 'SHP-9');
      expect(copy.sent, 7);
      expect(copy.lastFix, same(fix));
    });

    // FALENCIA DETECTADA (truck_tracking_state.dart:18-30): copyWith usa el
    // patrón `x ?? this.x`, por lo que NO puede volver a null los campos
    // nullables (shipmentId/lastFix). El servicio nunca lo necesita hoy, pero el
    // contrato de copyWith es incompleto: pasar shipmentId:null se ignora.
    test('copyWith NO puede limpiar shipmentId a null (comportamiento correcto '
        'esperado: debería poder)', () {
      const state = TruckTrackingState(active: true, shipmentId: 'SHP-1');
      final cleared = state.copyWith(shipmentId: null);
      // Comportamiento CORRECTO esperado: shipmentId debería quedar en null.
      expect(cleared.shipmentId, isNull);
    });
  });
}
