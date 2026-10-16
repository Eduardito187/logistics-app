import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/location_gate_status.dart';

// El enum del gate solo tiene tres estados; se fija el contrato (valores y
// orden) para que la UI del gate pueda confiar en ellos.
void main() {
  test('LocationGateStatus tiene exactamente checking/granted/denied', () {
    expect(LocationGateStatus.values, <LocationGateStatus>[
      LocationGateStatus.checking,
      LocationGateStatus.granted,
      LocationGateStatus.denied,
    ]);
  });
}
