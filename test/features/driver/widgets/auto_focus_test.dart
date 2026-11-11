import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_map.dart';

// Regla del auto-enfoque del mapa de entrega: se acerca al camión SOLO cuando
// todo está quieto (mapa sin gesto y camión sin moverse) por la ventana dada.

void main() {
  final now = DateTime(2026, 11, 11, 10, 0, 0);
  const window = Duration(seconds: 6);
  // Hace rato: fuera de la ventana.
  final old = now.subtract(const Duration(seconds: 30));
  // Recién: dentro de la ventana.
  final recent = now.subtract(const Duration(seconds: 2));

  bool call({
    DateTime? truckStillSince,
    DateTime? lastGestureAt,
    bool follow = false,
    bool autoFocused = false,
    bool animating = false,
  }) => shouldAutoFocus(
    now: now,
    truckStillSince: truckStillSince,
    lastGestureAt: lastGestureAt ?? old,
    follow: follow,
    autoFocused: autoFocused,
    animating: animating,
    window: window,
  );

  test('todo quieto el tiempo suficiente → enfoca', () {
    expect(call(truckStillSince: old, lastGestureAt: old), isTrue);
  });

  test('el camión aún no está (sin posición de reposo) → no enfoca', () {
    expect(call(truckStillSince: null), isFalse);
  });

  test('el camión recién paró (dentro de la ventana) → no enfoca', () {
    expect(call(truckStillSince: recent, lastGestureAt: old), isFalse);
  });

  test('el usuario tocó el mapa recién → no enfoca', () {
    expect(call(truckStillSince: old, lastGestureAt: recent), isFalse);
  });

  test('modo seguir activo → no enfoca (el seguir ya centra)', () {
    expect(call(truckStillSince: old, follow: true), isFalse);
  });

  test('ya se enfocó para esta quietud → no repite', () {
    expect(call(truckStillSince: old, autoFocused: true), isFalse);
  });

  test('hay otra animación de cámara en curso → no la pisa', () {
    expect(call(truckStillSince: old, animating: true), isFalse);
  });

  test('en el borde exacto de la ventana → enfoca', () {
    expect(
      call(
        truckStillSince: now.subtract(window),
        lastGestureAt: now.subtract(window),
      ),
      isTrue,
    );
  });
}
