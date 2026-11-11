import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/domain/entities/route_navigation.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_status_card.dart';

// `arrivedAtStop`: el camión "llegó" si está dentro de la geocerca
// (kArrivalMeters) y NO fuera de ruta.

RemainingEstimate _est({required double meters, bool offRoute = false}) =>
    RemainingEstimate(
      meters: meters,
      duration: Duration.zero,
      alongRoute: true,
      offRoute: offRoute,
    );

void main() {
  test('cerca y en ruta => llegó', () {
    expect(arrivedAtStop(_est(meters: 30)), isTrue);
  });

  test('en el borde exacto de la geocerca => llegó', () {
    expect(arrivedAtStop(_est(meters: kArrivalMeters)), isTrue);
  });

  test('justo más lejos que la geocerca => no llegó', () {
    expect(arrivedAtStop(_est(meters: kArrivalMeters + 1)), isFalse);
  });

  test('lejos => no llegó', () {
    expect(arrivedAtStop(_est(meters: 2000)), isFalse);
  });

  test('cerca pero FUERA de ruta => no llegó (no confiar en la geocerca)', () {
    expect(arrivedAtStop(_est(meters: 20, offRoute: true)), isFalse);
  });
}
