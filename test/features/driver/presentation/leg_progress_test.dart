import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/domain/entities/route_navigation.dart';
import 'package:logistics_app/features/driver/presentation/active_delivery_screen.dart';

// Avance del tramo hacia la parada en curso (barra de "Entrega en curso"): sale
// de la distancia que falta, se muestrea cada 10 s y nunca retrocede.

RemainingEstimate _at(double meters, {bool offRoute = false}) =>
    RemainingEstimate(
      meters: meters,
      duration: const Duration(minutes: 5),
      alongRoute: true,
      offRoute: offRoute,
    );

void main() {
  final t0 = DateTime(2026, 11, 14, 9);
  DateTime after(int seconds) => t0.add(Duration(seconds: seconds));

  test('sin posición no hay avance', () {
    final leg = LegProgress();
    expect(leg.sample(stopId: 'a', remaining: null, now: t0), 0);
  });

  test('avanza según la distancia recorrida del tramo', () {
    final leg = LegProgress();
    expect(leg.sample(stopId: 'a', remaining: _at(2000), now: t0), 0);
    expect(
      leg.sample(stopId: 'a', remaining: _at(1500), now: after(10)),
      closeTo(0.25, 1e-9),
    );
    expect(
      leg.sample(stopId: 'a', remaining: _at(500), now: after(20)),
      closeTo(0.75, 1e-9),
    );
  });

  test('entre muestras (menos de 10 s) no se mueve', () {
    final leg = LegProgress();
    leg.sample(stopId: 'a', remaining: _at(2000), now: t0);
    expect(leg.sample(stopId: 'a', remaining: _at(1000), now: after(4)), 0);
    expect(
      leg.sample(stopId: 'a', remaining: _at(1000), now: after(10)),
      closeTo(0.5, 1e-9),
    );
  });

  test('nunca retrocede aunque el GPS salte hacia atrás', () {
    final leg = LegProgress();
    leg.sample(stopId: 'a', remaining: _at(2000), now: t0);
    leg.sample(stopId: 'a', remaining: _at(1000), now: after(10));
    expect(
      leg.sample(stopId: 'a', remaining: _at(1400), now: after(20)),
      closeTo(0.5, 1e-9),
    );
  });

  test('al llegar a la parada el tramo se completa al instante', () {
    final leg = LegProgress();
    leg.sample(stopId: 'a', remaining: _at(2000), now: t0);
    expect(leg.sample(stopId: 'a', remaining: _at(40), now: after(2)), 1);
  });

  test('otra parada arranca de cero', () {
    final leg = LegProgress();
    leg.sample(stopId: 'a', remaining: _at(2000), now: t0);
    leg.sample(stopId: 'a', remaining: _at(500), now: after(10));
    expect(leg.sample(stopId: 'b', remaining: _at(3000), now: after(11)), 0);
  });
}
