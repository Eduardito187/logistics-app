import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/home_widgets/home_widget_kind.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_service.dart';

// Contrato del canal `bo.com.dismac/widgets` (lo implementan Kotlin y Swift):
// nombres de método y forma exacta de los argumentos.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = HomeWidgetsService.defaultChannel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'isSupported' => {'pinSupported': true},
        'requestPin' => true,
        _ => null,
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('nombre del canal', () {
    expect(channel.name, 'bo.com.dismac/widgets');
  });

  test('isSupported → pinSupported', () async {
    final support = await const HomeWidgetsService().isSupported();
    expect(support.pinSupported, isTrue);
  });

  test('update / clearAll / setEnabledKinds / requestPin', () async {
    const service = HomeWidgetsService();
    await service.update(HomeWidgetKind.routeDay, {'state': 'ok'});
    await service.clearAll();
    await service.setEnabledKinds([
      HomeWidgetKind.nextDelivery,
      HomeWidgetKind.quickScan,
    ]);
    final pinned = await service.requestPin(HomeWidgetKind.quickScan);
    expect(pinned, isTrue);
    expect(calls.map((c) => c.method), [
      'update',
      'clearAll',
      'setEnabledKinds',
      'requestPin',
    ]);
    expect(calls[0].arguments, {
      'kind': 'route_day',
      'payload': {'state': 'ok'},
    });
    expect(calls[2].arguments, {
      'kinds': ['next_delivery', 'quick_scan'],
    });
    expect(calls[3].arguments, {'kind': 'quick_scan'});
  });

  test('sin canal (MissingPluginException) todo es no-op', () async {
    messenger.setMockMethodCallHandler(channel, null);
    const service = HomeWidgetsService();
    await service.update(HomeWidgetKind.quickScan, const {});
    await service.clearAll();
    await service.setEnabledKinds(const []);
    expect(await service.requestPin(HomeWidgetKind.quickScan), isFalse);
    expect((await service.isSupported()).pinSupported, isFalse);
  });

  test('error del nativo no se propaga', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'boom');
    });
    expect(
      await const HomeWidgetsService().requestPin(HomeWidgetKind.routeDay),
      isFalse,
    );
  });
}
