import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/device/max_brightness_while_visible.dart';
import 'package:logistics_app/core/device/screen_brightness_service.dart';

class _FakeBrightness extends ScreenBrightnessService {
  final List<String> calls = [];

  @override
  Future<void> boost() async => calls.add('boost');

  @override
  Future<void> restore() async => calls.add('restore');
}

void main() {
  testWidgets('sube el brillo al mostrarse y lo devuelve al cerrarse', (
    tester,
  ) async {
    final fake = _FakeBrightness();
    final show = ValueNotifier<bool>(true);
    addTearDown(show.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [screenBrightnessServiceProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: show,
            builder: (_, visible, _) => visible
                ? const MaxBrightnessWhileVisible(child: Text('QR'))
                : const SizedBox(),
          ),
        ),
      ),
    );
    expect(find.text('QR'), findsOneWidget);
    expect(fake.calls, ['boost']);

    show.value = false;
    await tester.pump();
    expect(fake.calls, ['boost', 'restore']);
  });

  testWidgets('sin canal nativo no rompe', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MaxBrightnessWhileVisible(child: Text('QR'))),
      ),
    );
    expect(find.text('QR'), findsOneWidget);
  });

  test('el servicio usa el canal bo.com.dismac/screen', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(
      ScreenBrightnessService.defaultChannel,
      (call) async {
        calls.add(call.method);
        return true;
      },
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        ScreenBrightnessService.defaultChannel,
        null,
      ),
    );
    const service = ScreenBrightnessService();
    await service.boost();
    await service.restore();
    expect(calls, ['boostBrightness', 'restoreBrightness']);
  });
}
