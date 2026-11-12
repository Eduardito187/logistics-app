import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/network_info_channel.dart';
import 'package:logistics_app/core/printing/network_interface_info.dart';

// Canal nativo `bo.com.dismac/network` (lado Dart): máscara real de las
// interfaces y búsqueda mDNS. Sin canal o con error cae a dart:io (/24) y a
// "sin servicios" sin romper la búsqueda.

const _channel = MethodChannel('bo.com.dismac/network-test');

const _fallbackResult = [NetworkInterfaceInfo(name: 'wlan0', ip: '10.0.0.9')];

Future<List<NetworkInterfaceInfo>> _fallback() async => _fallbackResult;

void _mock(Future<Object?>? Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = NetworkInfoChannel(channel: _channel, fallback: _fallback);

  group('interfaces', () {
    test('usa la máscara real del canal', () async {
      _mock((call) async {
        expect(call.method, 'interfaces');
        return [
          {'name': 'wlan0', 'ip': '10.168.50.17', 'prefixLength': 23},
          {'name': 'eth1', 'ip': '172.30.220.5', 'prefixLength': 20},
        ];
      });

      final list = await channel.interfaces();

      expect(list, const [
        NetworkInterfaceInfo(
          name: 'wlan0',
          ip: '10.168.50.17',
          prefixLength: 23,
        ),
        NetworkInterfaceInfo(
          name: 'eth1',
          ip: '172.30.220.5',
          prefixLength: 20,
        ),
      ]);
    });

    test('sin canal (MissingPluginException) -> dart:io /24', () async {
      // Sin handler: el canal lanza MissingPluginException.
      expect(await channel.interfaces(), _fallbackResult);
    });

    test('PlatformException -> dart:io /24', () async {
      _mock((call) async => throw PlatformException(code: 'boom'));

      expect(await channel.interfaces(), _fallbackResult);
    });

    test('lista vacía del canal -> dart:io', () async {
      _mock((call) async => <Object?>[]);

      expect(await channel.interfaces(), _fallbackResult);
    });

    test('parseInterfaces descarta basura y corrige máscaras inválidas', () {
      final list = NetworkInfoChannel.parseInterfaces([
        {'name': 'wlan0', 'ip': '192.168.1.5', 'prefixLength': 99},
        {'name': 'wlan1', 'ip': '192.168.2.5'},
        {'ip': '192.168.3.5', 'prefixLength': 24},
        'basura',
        null,
      ]);

      expect(list.map((i) => i.prefixLength), [24, 24]);
      expect(list.map((i) => i.name), ['wlan0', 'wlan1']);
    });
  });

  group('discoverServices', () {
    test('pasa tipos y timeout; mapea los servicios', () async {
      MethodCall? received;
      _mock((call) async {
        received = call;
        return [
          {
            'name': 'RICOH IM 550',
            'type': '_pdl-datastream._tcp',
            'host': '192.168.2.154',
            'port': 9100,
            'txt': {'product': '(RICOH IM 550)', 'ty': 'RICOH IM 550'},
          },
          {'name': 'sin host'},
        ];
      });

      final services = await channel.discoverServices(
        NetworkInfoChannel.printerServiceTypes,
        const Duration(seconds: 4),
      );

      expect(received!.method, 'discoverServices');
      expect(received!.arguments, {
        'types': ['_pdl-datastream._tcp', '_printer._tcp', '_ipp._tcp'],
        'timeoutMs': 4000,
      });
      final s = services.single;
      expect(s.name, 'RICOH IM 550');
      expect(s.host, '192.168.2.154');
      expect(s.port, 9100);
      expect(s.txt['ty'], 'RICOH IM 550');
    });

    test('sin canal -> vacío, sin error', () async {
      expect(
        await channel.discoverServices(const ['_ipp._tcp'], Duration.zero),
        isEmpty,
      );
    });

    test('PlatformException -> vacío', () async {
      _mock((call) async => throw PlatformException(code: 'nsd'));

      expect(
        await channel.discoverServices(const ['_ipp._tcp'], Duration.zero),
        isEmpty,
      );
    });
  });
}
