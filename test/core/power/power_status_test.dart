import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/power/motion_budget.dart';
import 'package:logistics_app/core/power/power_channel.dart';
import 'package:logistics_app/core/power/power_status.dart';
import 'package:logistics_app/core/power/power_status_notifier.dart';

// Estado de energía: lectura del canal nativo (con canal falso), degradación
// sin plugin y publicación en MotionBudget para recortar animaciones.

const _channel = MethodChannel('bo.com.dismac/power');

class _FakePowerChannel extends PowerChannel {
  _FakePowerChannel(this.status);

  PowerStatus status;
  int reads = 0;

  @override
  Future<PowerStatus> read() async {
    reads++;
    return status;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    MotionBudget.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('PowerStatus', () {
    test('desconocido = comportamiento normal (sin ahorro)', () {
      expect(PowerStatus.unknown.shouldSaveEnergy, isFalse);
      expect(PowerStatus.unknown.isLowBattery, isFalse);
    });

    test('ahorro del sistema activo → ahorra', () {
      expect(
        const PowerStatus(level: 90, powerSave: true).shouldSaveEnergy,
        isTrue,
      );
    });

    test('batería < 20 % sin cargar → ahorra; cargando no', () {
      expect(const PowerStatus(level: 19).shouldSaveEnergy, isTrue);
      expect(const PowerStatus(level: 20).shouldSaveEnergy, isFalse);
      expect(
        const PowerStatus(level: 10, charging: true).shouldSaveEnergy,
        isFalse,
      );
    });

    test('fromMap lee el canal y descarta niveles fuera de rango', () {
      expect(
        PowerStatus.fromMap(const {
          'level': 42,
          'charging': true,
          'powerSave': false,
        }),
        const PowerStatus(level: 42, charging: true),
      );
      expect(PowerStatus.fromMap(const {'level': -1}).level, isNull);
      expect(PowerStatus.fromMap(const {'level': 150}).level, isNull);
      expect(PowerStatus.fromMap(null), PowerStatus.unknown);
    });
  });

  group('PowerChannel', () {
    test('lee "status" del canal nativo', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            expect(call.method, 'status');
            return {'level': 15, 'charging': false, 'powerSave': true};
          });
      final status = await const PowerChannel().read();
      expect(status, const PowerStatus(level: 15, powerSave: true));
      expect(status.shouldSaveEnergy, isTrue);
    });

    test('sin plugin (MissingPluginException) → desconocido, sin error', () {
      expect(const PowerChannel().read(), completion(PowerStatus.unknown));
    });

    test('error del canal → desconocido', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            throw PlatformException(code: 'power_unavailable');
          });
      expect(await const PowerChannel().read(), PowerStatus.unknown);
    });
  });

  group('PowerStatusNotifier', () {
    ProviderContainer containerWith(_FakePowerChannel channel) {
      final c = ProviderContainer(
        overrides: [powerChannelProvider.overrideWithValue(channel)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('lee al crearse y publica el ahorro en MotionBudget', () async {
      final channel = _FakePowerChannel(
        const PowerStatus(level: 50, powerSave: true),
      );
      final container = containerWith(channel);
      expect(container.read(powerStatusProvider), PowerStatus.unknown);
      await pumpEventQueue();
      expect(container.read(powerStatusProvider).powerSave, isTrue);
      expect(MotionBudget.powerSaving.value, isTrue);
      expect(MotionBudget.decorativeAllowed, isFalse);

      channel.status = const PowerStatus(level: 50);
      await container.read(powerStatusProvider.notifier).refresh();
      expect(MotionBudget.powerSaving.value, isFalse);
    });

    test('refreshIfStale no toca el canal si la lectura es reciente', () async {
      final channel = _FakePowerChannel(const PowerStatus(level: 80));
      final container = containerWith(channel);
      final notifier = container.read(powerStatusProvider.notifier);
      await pumpEventQueue();
      final reads = channel.reads;

      await notifier.refreshIfStale();
      expect(channel.reads, reads);

      await notifier.refreshIfStale(
        now: DateTime.now().add(PowerStatusNotifier.maxAge),
      );
      expect(channel.reads, reads + 1);
    });

    test('al volver a primer plano relee el estado', () async {
      // Parte de "primer plano" (sin listeners todavía: no valida transición).
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      final channel = _FakePowerChannel(const PowerStatus(level: 80));
      final container = containerWith(channel);
      container.read(powerStatusProvider);
      await pumpEventQueue();
      final reads = channel.reads;

      final binding = WidgetsBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(channel.reads, reads + 1);
    });
  });

  group('MotionBudget', () {
    test('loop de cargando: ~30 s normal, ~5 s con ahorro, mínimo 1', () {
      const cycle = Duration(milliseconds: 1000);
      expect(MotionBudget.loadingCyclesFor(cycle), 30);
      MotionBudget.powerSaving.value = true;
      expect(MotionBudget.loadingCyclesFor(cycle), 5);
      expect(MotionBudget.loadingCyclesFor(const Duration(seconds: 9)), 1);
      expect(MotionBudget.loadingCyclesFor(Duration.zero), 1);
    });
  });
}

