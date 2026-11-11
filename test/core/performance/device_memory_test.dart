import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/performance/device_memory.dart';
import 'package:logistics_app/core/performance/memory_pressure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/device_memory');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('DeviceMemory.load', () {
    test('lee RAM total y bandera de poca RAM del canal nativo', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => {'totalMb': 980, 'lowRam': true, 'memoryClassMb': 96},
      );

      final memory = await DeviceMemory.load(channel: channel);

      expect(memory.totalMb, 980);
      expect(memory.memoryClassMb, 96);
      expect(memory.lowRam, isTrue);
      expect(memory.isLowEnd, isTrue);
      expect(memory.isVeryLowEnd, isFalse); // 980 MB / heap 96 MB: no es Go 512
    });

    test(
      'canal caído o sin implementar: equipo desconocido, sin fallar',
      () async {
        messenger.setMockMethodCallHandler(
          channel,
          (call) async => throw PlatformException(code: 'x'),
        );
        final memory = await DeviceMemory.load(channel: channel);
        expect(memory.totalMb, isNull);
        expect(memory.isLowEnd, isFalse);

        messenger.setMockMethodCallHandler(channel, null);
        expect((await DeviceMemory.load(channel: channel)).totalMb, isNull);
      },
    );
  });

  group('DeviceMemory.isVeryLowEnd (512 MB / Android Go real)', () {
    test('≤768 MB de RAM total cuenta como gama extrema', () {
      expect(const DeviceMemory(totalMb: 512).isVeryLowEnd, isTrue);
      expect(const DeviceMemory(totalMb: 768).isVeryLowEnd, isTrue);
      expect(const DeviceMemory(totalMb: 1024).isVeryLowEnd, isFalse);
    });

    test('heap Java (memoryClass) ≤24 MB cuenta como gama extrema', () {
      // Aunque el equipo reporte más RAM total, un heap chico delata el Go.
      expect(
        const DeviceMemory(totalMb: 1024, memoryClassMb: 24).isVeryLowEnd,
        isTrue,
      );
      expect(
        const DeviceMemory(totalMb: 1024, memoryClassMb: 32).isVeryLowEnd,
        isFalse,
      );
    });

    test('equipo desconocido NO es gama extrema (se asume gama media)', () {
      expect(DeviceMemory.unknown.isVeryLowEnd, isFalse);
    });
  });

  group('MemoryBudget.forDevice', () {
    test(
      '512 MB (gama extrema): caché mínima y trim, antes del tier de 1 GB',
      () {
        final b = MemoryBudget.forDevice(const DeviceMemory(totalMb: 512));
        expect(b.imageCacheBytes, 10 << 20);
        expect(b.imageCacheCount, 24);
        expect(b.trimOnBackground, isTrue);

        // El tier extremo gana aunque también sea isLowEnd (heap chico).
        final byHeap = MemoryBudget.forDevice(
          const DeviceMemory(totalMb: 1024, memoryClassMb: 20),
        );
        expect(byHeap.imageCacheBytes, 10 << 20);
      },
    );

    test('1 GB: caché chica y se libera al ir a segundo plano', () {
      final b = MemoryBudget.forDevice(const DeviceMemory(totalMb: 1024));
      expect(b.imageCacheBytes, 24 << 20);
      expect(b.imageCacheCount, 50);
      expect(b.trimOnBackground, isTrue);
    });

    test('Android Go (lowRam) aunque reporte 2 GB cuenta como gama baja', () {
      final b = MemoryBudget.forDevice(
        const DeviceMemory(totalMb: 2048, lowRam: true),
      );
      expect(b.imageCacheBytes, 24 << 20);
    });

    test('2–3 GB y desconocido: 40 MB; más de 3 GB: 64 MB', () {
      expect(
        MemoryBudget.forDevice(
          const DeviceMemory(totalMb: 3072),
        ).imageCacheBytes,
        40 << 20,
      );
      expect(
        MemoryBudget.forDevice(DeviceMemory.unknown).imageCacheBytes,
        40 << 20,
      );
      final high = MemoryBudget.forDevice(const DeviceMemory(totalMb: 6144));
      expect(high.imageCacheBytes, 64 << 20);
      expect(high.trimOnBackground, isFalse);
    });
  });

  group('MemoryPressureObserver', () {
    test('aplica el tope a la caché de imágenes', () {
      final cache = ImageCache();
      applyImageCacheBudget(
        MemoryBudget.forDevice(const DeviceMemory(totalMb: 1024)),
        cache: cache,
      );
      expect(cache.maximumSizeBytes, 24 << 20);
      expect(cache.maximumSize, 50);
    });

    test('libera ante presión de memoria y, en gama baja, al pausar', () {
      final low = MemoryPressureObserver(
        budget: MemoryBudget.forDevice(const DeviceMemory(totalMb: 1024)),
        cache: ImageCache(),
      );
      low.didHaveMemoryPressure();
      low.didChangeAppLifecycleState(AppLifecycleState.paused);
      low.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(low.trims, 2);

      final high = MemoryPressureObserver(
        budget: MemoryBudget.forDevice(const DeviceMemory(totalMb: 6144)),
        cache: ImageCache(),
      );
      high.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(high.trims, 0);
      high.didHaveMemoryPressure();
      expect(high.trims, 1);
    });
  });
}
