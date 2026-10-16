import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/scanning/scan_feedback.dart';

import '../auth/test_fakes.dart';

// Aviso al escanear: éxito = vibración fuerte + click del sistema; error =
// doble vibración. Se verifica por el canal `flutter/platform` y que la
// preferencia "Vibrar y sonar al escanear" (default ON) se respete y persista.

final List<MethodCall> _calls = [];

void _mockPlatform({bool fail = false}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        _calls.add(call);
        if (fail) throw PlatformException(code: 'sin_vibrador');
        return null;
      });
}

List<String> _summary() => [
  for (final c in _calls)
    c.arguments == null ? c.method : '${c.method}:${c.arguments}',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _calls.clear();
    _mockPlatform();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('éxito: vibración fuerte y click del sistema', () async {
    await scanSuccessFeedback();
    expect(_summary(), [
      'HapticFeedback.vibrate:HapticFeedbackType.heavyImpact',
      'SystemSound.play:SystemSoundType.click',
    ]);
  });

  test('error: doble vibración y sin sonido', () async {
    await scanErrorFeedback();
    expect(_summary(), ['HapticFeedback.vibrate', 'HapticFeedback.vibrate']);
  });

  test('sin vibrador (el canal falla) no lanza', () async {
    _mockPlatform(fail: true);
    await expectLater(scanSuccessFeedback(), completes);
    await expectLater(scanErrorFeedback(), completes);
  });

  group('preferencia', () {
    test('por defecto activada y persiste al cambiarla', () async {
      final storage = FakeSecureStorage();
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      expect(container.read(scanFeedbackEnabledProvider), isTrue);

      await container.read(scanFeedbackEnabledProvider.notifier).set(false);
      expect(container.read(scanFeedbackEnabledProvider), isFalse);
      expect(storage.data[ScanFeedbackEnabledNotifier.storageKey], 'false');
    });

    test('carga el valor guardado', () async {
      final storage = FakeSecureStorage()
        ..seed(ScanFeedbackEnabledNotifier.storageKey, 'false');
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(scanFeedbackEnabledProvider, (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(scanFeedbackEnabledProvider), isFalse);
    });
  });

  group('scanFeedbackFor', () {
    Future<BuildContext> pumpHost(
      WidgetTester tester, {
      ProviderContainer? container,
    }) async {
      late BuildContext ctx;
      final host = MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(
        container == null
            ? host
            : UncontrolledProviderScope(container: container, child: host),
      );
      return ctx;
    }

    testWidgets('sin ProviderScope avisa (default activado)', (tester) async {
      final ctx = await pumpHost(tester);
      _calls.clear();
      await scanFeedbackFor(ctx, success: true);
      expect(_summary(), contains('SystemSound.play:SystemSoundType.click'));
    });

    testWidgets('desactivado en Ajustes no vibra ni suena', (tester) async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(scanFeedbackEnabledProvider.notifier).set(false);
      final ctx = await pumpHost(tester, container: container);
      _calls.clear();
      await scanFeedbackFor(ctx, success: true);
      await scanFeedbackFor(ctx, success: false);
      expect(_calls, isEmpty);
    });

    testWidgets('activado: error da doble vibración', (tester) async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
        ],
      );
      addTearDown(container.dispose);
      final ctx = await pumpHost(tester, container: container);
      _calls.clear();
      final done = scanFeedbackFor(ctx, success: false);
      await tester.pump(kScanErrorVibrationGap);
      await done;
      expect(_summary(), ['HapticFeedback.vibrate', 'HapticFeedback.vibrate']);
    });
  });
}
