import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/animated_driver_markers.dart';

// El camión se DESLIZA entre un fix y el siguiente (como las apps de taxi), no
// salta: la posición mostrada interpola la anterior hasta la nueva a lo largo
// del tiempo real que tardó el fix.

/// Lee el punto del marcador del camión (el segundo del MarkerLayer; el primero
/// es el radar). Ambos comparten la posición interpolada.
LatLng _truckPoint(WidgetTester tester) =>
    tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers[1].point;

/// Monta el widget con un objetivo cambiable desde afuera.
Future<void Function(LatLng)> _pump(
  WidgetTester tester, {
  required LatLng initial,
  bool reduceMotion = false,
}) async {
  late void Function(void Function()) setOuter;
  var target = initial;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return FlutterMap(
              options: MapOptions(initialCenter: initial, initialZoom: 15),
              children: [
                AnimatedDriverMarkers(
                  target: target,
                  heading: 0,
                  reduceMotion: reduceMotion,
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  return (LatLng next) => setOuter(() => target = next);
}

void main() {
  setUp(() {
    // Reloj controlado: la separación entre fixes fija la duración del glide.
    var t = DateTime(2026, 11, 17, 8);
    AnimatedDriverMarkers.clock = () => t = t.add(const Duration(seconds: 2));
  });
  tearDown(() => AnimatedDriverMarkers.clock = DateTime.now);

  testWidgets('el primer fix real salta directo (no desliza desde nada)', (
    tester,
  ) async {
    final move = await _pump(tester, initial: const LatLng(-17.79, -63.19));
    // Primer fix tras montar: snap (no hay "desde" con sentido todavía).
    move(const LatLng(-17.78, -63.18));
    await tester.pump();
    expect(_truckPoint(tester).latitude, closeTo(-17.78, 1e-9));
    expect(_truckPoint(tester).longitude, closeTo(-63.18, 1e-9));
    await tester.pumpAndSettle();
  });

  testWidgets('los fixes siguientes se deslizan: queda a mitad de camino', (
    tester,
  ) async {
    final move = await _pump(tester, initial: const LatLng(-17.79, -63.19));
    // Primer fix: snap (deja marcada la hora del fix anterior).
    move(const LatLng(-17.79, -63.19));
    await tester.pump();
    // Segundo fix (2 s después, según el reloj): desliza en 2 s.
    move(const LatLng(-17.79, -63.17));
    await tester.pump(); // arranca el glide
    await tester.pump(const Duration(seconds: 1)); // mitad del recorrido

    final mid = _truckPoint(tester);
    // A mitad de un glide lineal: entre el origen y el destino, sin haber
    // llegado (eso es lo que evita el "salto").
    expect(mid.longitude, greaterThan(-63.19));
    expect(mid.longitude, lessThan(-63.17));
    expect(mid.longitude, closeTo(-63.18, 0.004));

    // Al terminar, llega exacto al destino.
    await tester.pumpAndSettle();
    expect(_truckPoint(tester).longitude, closeTo(-63.17, 1e-6));
  });

  testWidgets('con reduce-motion salta directo (sin deslizar)', (tester) async {
    final move = await _pump(
      tester,
      initial: const LatLng(-17.79, -63.19),
      reduceMotion: true,
    );
    move(const LatLng(-17.79, -63.19));
    await tester.pump();
    move(const LatLng(-17.79, -63.17));
    await tester.pump();
    // Sin animación en curso: ya está en el destino.
    expect(_truckPoint(tester).longitude, closeTo(-63.17, 1e-9));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
