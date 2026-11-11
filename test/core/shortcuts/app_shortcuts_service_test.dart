import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/shortcuts/app_shortcut.dart';
import 'package:logistics_app/core/shortcuts/app_shortcuts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = AppShortcutsService.defaultChannel;
  late TestDefaultBinaryMessenger messenger;
  late List<MethodCall> calls;

  setUp(() {
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'consumeLaunchShortcut' ? '/driver/delivery' : true;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('set manda la lista de accesos; clear los borra', () async {
    final service = AppShortcutsService();
    await service.set(const [
      AppShortcut(
        id: 'driver-active-delivery',
        title: 'Entrega en curso',
        shortTitle: 'Entrega',
        route: '/driver/delivery',
      ),
    ]);
    await service.clear();
    expect(calls.map((c) => c.method), ['set', 'clear']);
    final items = calls.first.arguments as List;
    expect(items.single, {
      'id': 'driver-active-delivery',
      'title': 'Entrega en curso',
      'shortTitle': 'Entrega',
      'route': '/driver/delivery',
    });
  });

  test('consumeLaunchShortcut devuelve la ruta de arranque', () async {
    expect(
      await AppShortcutsService().consumeLaunchShortcut(),
      '/driver/delivery',
    );
  });

  test('consumeLaunchShortcut descarta lo que no es una ruta', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'javascript:x');
    expect(await AppShortcutsService().consumeLaunchShortcut(), isNull);
  });

  test('"launch" del nativo llega por el stream', () async {
    final service = AppShortcutsService();
    final received = <String>[];
    final sub = service.launches.listen(received.add);
    addTearDown(sub.cancel);
    addTearDown(service.dispose);

    Future<void> send(Object? route) =>
        messenger.handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(MethodCall('launch', route)),
          (_) {},
        );

    await send('/store/reception');
    await send('no-es-ruta');
    await Future<void>.delayed(Duration.zero);
    expect(received, ['/store/reception']);
  });

  test('sin plugin todo es no-op', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final service = AppShortcutsService();
    await service.set(const []);
    await service.clear();
    expect(await service.consumeLaunchShortcut(), isNull);
  });
}
