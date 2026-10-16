import 'package:integration_test/integration_test.dart';

import 'flows/driver_delivery_flow.dart';
import 'flows/login_flow.dart';
import 'flows/picking_flow.dart';
import 'flows/store_reception_flow.dart';

// Tests de integración (e2e) de los 4 flujos críticos con la app REAL
// (`LogisticsApp`) y dobles solo en los bordes (backend, cámara, GPS,
// impresora, storage). Un único punto de entrada: en un dispositivo se compila
// e instala UNA sola vez para todos los flujos. Ver docs/e2e.md.
//
// - Host:        flutter test integration_test -d flutter-tester
// - Dispositivo: flutter test integration_test -d <id> \
//                  --dart-define-from-file=config/dev.json
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  loginFlowTests();
  driverDeliveryFlowTests();
  storeReceptionFlowTests();
  pickingFlowTests();
}
