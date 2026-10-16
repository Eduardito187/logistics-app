import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/widgets/stop_map_screen.dart';

import '../support/driver_test_support.dart';

// Mapa a pantalla completa centrado en una parada.

void main() {
  testWidgets('muestra el nombre del cliente y el mapa', (tester) async {
    await pumpScoped(
      tester,
      child: StopMapScreen(
        stop: buildStop(customerName: 'Depósito Norte', lat: -16.5, lng: -68.1),
      ),
    );

    expect(find.text('Depósito Norte'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
