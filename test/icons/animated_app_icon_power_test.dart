import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/core/power/motion_budget.dart';
import 'package:logistics_app/features/driver/presentation/widgets/radar_pulse.dart';

// Batería: los loops de animación tienen tope y las animaciones decorativas se
// apagan con ahorro de energía / batería baja (MotionBudget).

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  tearDown(MotionBudget.reset);

  testWidgets('un ícono en loading deja de animar tras el tope (~30 s)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const AnimatedAppIcon(AppIcon.syncing, state: AppIconState.loading),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(tester.hasRunningAnimations, isTrue);

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.hasRunningAnimations, isFalse);
    // Sigue mostrando su estado (solo sin movimiento).
    expect(
      find.byWidgetPredicate(
        (w) => w is AnimatedAppIcon && w.state == AppIconState.loading,
      ),
      findsOneWidget,
    );
  });

  testWidgets('con ahorro de energía el loop de loading se corta a ~5 s', (
    tester,
  ) async {
    MotionBudget.powerSaving.value = true;
    await tester.pumpWidget(
      _host(
        const AnimatedAppIcon(AppIcon.syncing, state: AppIconState.loading),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.hasRunningAnimations, isTrue);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('con ahorro de energía el botón central NO respira', (
    tester,
  ) async {
    MotionBudget.powerSaving.value = true;
    await tester.pumpWidget(
      _host(const AnimatedAppIcon(AppIcon.deliver, ambient: true)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('volver a loading reinicia el loop con su tope', (tester) async {
    await tester.pumpWidget(
      _host(
        const AnimatedAppIcon(AppIcon.syncing, state: AppIconState.loading),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(
      _host(const AnimatedAppIcon(AppIcon.syncing, state: AppIconState.idle)),
    );
    await tester.pumpWidget(
      _host(
        const AnimatedAppIcon(AppIcon.syncing, state: AppIconState.loading),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  group('RadarPulse', () {
    testWidgets('pulso finito por lectura (1,2 s) y quieto entre lecturas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const RadarPulse(trigger: LatLng(-17.78, -63.18))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('con ahorro de energía queda estático', (tester) async {
      MotionBudget.powerSaving.value = true;
      await tester.pumpWidget(
        _host(const RadarPulse(trigger: LatLng(-17.78, -63.18))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);

      // Nueva lectura: tampoco anima.
      await tester.pumpWidget(
        _host(const RadarPulse(trigger: LatLng(-17.79, -63.18))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('activar el ahorro en caliente detiene el pulso', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const RadarPulse(trigger: LatLng(-17.78, -63.18))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      MotionBudget.powerSaving.value = true;
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
