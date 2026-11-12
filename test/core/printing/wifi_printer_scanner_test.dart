import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipv4.dart';
import 'package:logistics_app/core/printing/ipv4_subnet.dart';
import 'package:logistics_app/core/printing/mdns_service.dart';
import 'package:logistics_app/core/printing/network_interface_info.dart';
import 'package:logistics_app/core/printing/network_printer_identity.dart';
import 'package:logistics_app/core/printing/printer_reachability.dart';
import 'package:logistics_app/core/printing/wifi_hit_source.dart';
import 'package:logistics_app/core/printing/wifi_printer_scanner.dart';
import 'package:logistics_app/core/printing/wifi_scan_progress.dart';

// WifiPrinterScanner con todos los seams falsos: NUNCA toca la red real. Las
// interfaces, el probe TCP y la identificación HTTP se simulan en memoria.

const _ownIp = '192.168.1.50';

/// Red WiFi única del teléfono.
Future<List<NetworkInterfaceInfo>> _wlan() async => const [
  NetworkInterfaceInfo(name: 'wlan0', ip: _ownIp),
];

/// Probe que responde `true` solo para [open] y registra cada llamada.
class _FakeProbe {
  _FakeProbe([this.open = const {}, this.delay]);

  final Set<String> open;
  final Duration? delay;
  final List<String> hosts = [];
  final List<int> ports = [];
  int inFlight = 0;
  int maxInFlight = 0;

  Future<bool> call(String host, int port, Duration timeout) async {
    hosts.add(host);
    ports.add(port);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    final wait = delay;
    if (wait != null) await Future<void>.delayed(wait);
    inFlight--;
    return open.contains(host);
  }
}

/// Identificación por host según un mapa fijo.
PrinterIdentifier _identifyFrom(Map<String, NetworkPrinterIdentity> ids) =>
    (host, timeout) async => ids[host];

void main() {
  group('WifiPrinterScanner.scan — sin red local', () {
    test('sin interfaces emite un único failed y cierra', () async {
      final probe = _FakeProbe();
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => const [],
        probe: probe.call,
        identify: _identifyFrom(const {}),
      );

      final events = await scanner.scan().toList();

      expect(events, hasLength(1));
      expect(events.single.error, kNoLocalNetworkMessage);
      expect(events.single.done, isTrue);
      expect(probe.hosts, isEmpty);
    });

    test('solo datos móviles (rmnet) cuenta como sin red local', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => const [
          NetworkInterfaceInfo(name: 'rmnet_data0', ip: '10.20.30.40'),
        ],
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
      );

      final events = await scanner.scan().toList();

      expect(events.single.error, kNoLocalNetworkMessage);
    });

    test('listInterfaces que lanza se trata como sin red local', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => throw StateError('sin permiso'),
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
      );

      final events = await scanner.scan().toList();

      expect(events.single.error, kNoLocalNetworkMessage);
      expect(await scanner.localNetworks(), isEmpty);
    });
  });

  group('WifiPrinterScanner.scan — barrido del /24', () {
    test('prueba los 253 hosts (sin la IP propia) y cierra done', () async {
      final probe = _FakeProbe();
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {}),
      );

      final events = await scanner.scan().toList();

      expect(probe.hosts, hasLength(253));
      expect(probe.hosts.toSet(), hasLength(253));
      expect(probe.hosts, isNot(contains(_ownIp)));
      expect(probe.hosts, containsAll(['192.168.1.1', '192.168.1.254']));
      expect(probe.hosts, isNot(contains('192.168.1.0')));
      expect(probe.hosts, isNot(contains('192.168.1.255')));
      expect(probe.ports.toSet(), {9100});

      final first = events.first;
      expect(first.scanned, 0);
      expect(first.total, 253);
      expect(first.done, isFalse);
      expect(first.networkLabels, ['192.168.1.0/24']);
      expect(first.networks.single.isPartial, isFalse);

      final last = events.last;
      expect(last.done, isTrue);
      expect(last.total, 253);
      expect(last.scanned, last.total);
      expect(last.fraction, 1.0);
      expect(last.found, isEmpty);
      expect(last.error, isNull);
      expect(events.where((e) => e.done), hasLength(1));
    });

    test('el avance es monótono y nunca supera el total', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
      );

      final events = await scanner.scan().toList();

      var previous = -1;
      for (final e in events) {
        expect(e.scanned, greaterThanOrEqualTo(previous));
        expect(e.scanned, lessThanOrEqualTo(e.total));
        previous = e.scanned;
      }
    });

    test('dos redes: barre ambas y lista sus etiquetas', () async {
      final probe = _FakeProbe();
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => const [
          NetworkInterfaceInfo(name: 'eth0', ip: '10.0.0.7'),
          NetworkInterfaceInfo(name: 'wlan0', ip: _ownIp),
        ],
        probe: probe.call,
        identify: _identifyFrom(const {}),
      );

      final last = await scanner.scan().last;

      expect(last.total, 506);
      expect(last.scanned, 506);
      expect(last.networkLabels, ['192.168.1.0/24', '10.0.0.0/24']);
      expect(probe.hosts, isNot(contains('10.0.0.7')));
    });

    test('respeta el tope de concurrencia', () async {
      final probe = _FakeProbe(const {}, const Duration(milliseconds: 1));
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {}),
        concurrency: 5,
      );

      await scanner.scan().last;

      expect(probe.maxInFlight, lessThanOrEqualTo(5));
      expect(probe.maxInFlight, greaterThan(1));
      expect(probe.hosts, hasLength(253));
    });

    test('usa el puerto pedido en el probe y en los hits', () async {
      final probe = _FakeProbe({'192.168.1.9'});
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {}),
      );

      final last = await scanner.scan(port: 6101).last;

      expect(probe.ports.toSet(), {6101});
      expect(last.found.single.port, 6101);
      expect(last.found.single.address, '192.168.1.9:6101');
    });
  });

  group('WifiPrinterScanner.scan — impresoras encontradas', () {
    test('los hosts abiertos aparecen identificados y ordenados', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe({
          '192.168.1.10',
          '192.168.1.9',
          '192.168.1.200',
          '192.168.1.3',
        }).call,
        identify: _identifyFrom(const {
          '192.168.1.200': NetworkPrinterIdentity(
            name: 'Zebra ZD421',
            isZebra: true,
          ),
          '192.168.1.3': NetworkPrinterIdentity(
            name: 'HP LaserJet',
            isZebra: false,
          ),
        }),
      );

      final last = await scanner.scan().last;

      expect(last.found.map((h) => h.host), [
        '192.168.1.200',
        '192.168.1.3',
        '192.168.1.9',
        '192.168.1.10',
      ]);
      final zebra = last.found.first;
      expect(zebra.name, 'Zebra ZD421');
      expect(zebra.isZebra, isTrue);
      expect(zebra.port, 9100);
      expect(last.found[1].name, 'HP LaserJet');
      expect(last.found[1].isZebra, isFalse);
      expect(last.found[2].name, isNull);
      expect(last.found[3].name, isNull);
    });

    test('lo encontrado se emite en vivo antes del done', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe({'192.168.1.9'}).call,
        identify: _identifyFrom(const {}),
      );

      final events = await scanner.scan().toList();

      expect(events.any((e) => !e.done && e.found.isNotEmpty), isTrue);
    });

    test('identify que lanza -> hit sin nombre y no Zebra', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe({'192.168.1.9'}).call,
        identify: (host, timeout) async => throw StateError('http roto'),
      );

      final last = await scanner.scan().last;

      expect(last.done, isTrue);
      expect(last.error, isNull);
      final hit = last.found.single;
      expect(hit.host, '192.168.1.9');
      expect(hit.name, isNull);
      expect(hit.isZebra, isFalse);
    });

    test('identify recibe el identifyTimeout configurado', () async {
      Duration? received;
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe({'192.168.1.9'}).call,
        identify: (host, timeout) async {
          received = timeout;
          return null;
        },
        identifyTimeout: const Duration(milliseconds: 1234),
      );

      await scanner.scan().last;

      expect(received, const Duration(milliseconds: 1234));
    });
  });

  group('WifiPrinterScanner.scan — errores y cancelación', () {
    test('probe que lanza -> failed genérico al final', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: (host, port, timeout) async => throw StateError('boom'),
        identify: _identifyFrom(const {}),
      );

      final events = await scanner.scan().toList();

      final last = events.last;
      expect(last.done, isTrue);
      expect(last.error, isNotNull);
      expect(last.error, isNot(kNoLocalNetworkMessage));
      expect(last.error, contains('No se pudo buscar impresoras'));
    });

    test('cancelar la suscripción detiene el barrido', () async {
      final probe = _FakeProbe(const {}, const Duration(milliseconds: 5));
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {}),
        concurrency: 4,
      );

      await for (final p in scanner.scan()) {
        // Salir del await-for cancela la suscripción.
        if (p.scanned >= 8) break;
      }
      // Lo que estaba en vuelo termina; después no arranca nada nuevo.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final afterCancel = probe.hosts.length;
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(probe.hosts.length, afterCancel);
      expect(afterCancel, lessThan(253));
    });
  });

  group('WifiPrinterScanner.findByName', () {
    WifiPrinterScanner scannerWith(Map<String, NetworkPrinterIdentity> ids) =>
        WifiPrinterScanner(
          listInterfaces: _wlan,
          probe: _FakeProbe(ids.keys.toSet()).call,
          identify: _identifyFrom(ids),
        );

    test('devuelve la única coincidencia por nombre', () async {
      final scanner = scannerWith(const {
        '192.168.1.9': NetworkPrinterIdentity(
          name: 'Zebra ZD421',
          isZebra: true,
        ),
        '192.168.1.20': NetworkPrinterIdentity(name: 'HP', isZebra: false),
      });

      final hit = await scanner.findByName('Zebra ZD421');

      expect(hit, isNotNull);
      expect(hit!.host, '192.168.1.9');
      expect(hit.port, 9100);
    });

    test('pasa el puerto al barrido', () async {
      final probe = _FakeProbe({'192.168.1.9'});
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {
          '192.168.1.9': NetworkPrinterIdentity(name: 'Z', isZebra: true),
        }),
      );

      final hit = await scanner.findByName('Z', port: 6101);

      expect(hit!.address, '192.168.1.9:6101');
      expect(probe.ports.toSet(), {6101});
    });

    test('ninguna coincidencia -> null', () async {
      final scanner = scannerWith(const {
        '192.168.1.9': NetworkPrinterIdentity(name: 'HP', isZebra: false),
      });

      expect(await scanner.findByName('Zebra ZD421'), isNull);
    });

    test('dos impresoras con el mismo nombre -> null (ambigua)', () async {
      final scanner = scannerWith(const {
        '192.168.1.9': NetworkPrinterIdentity(
          name: 'Zebra ZD421',
          isZebra: true,
        ),
        '192.168.1.10': NetworkPrinterIdentity(
          name: 'Zebra ZD421',
          isZebra: true,
        ),
      });

      expect(await scanner.findByName('Zebra ZD421'), isNull);
    });

    test('sin red local -> null', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => const [],
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
      );

      expect(await scanner.findByName('Zebra ZD421'), isNull);
    });
  });

  group('WifiPrinterScanner — probe y localNetworks', () {
    test('probe delega en el seam con el puerto por defecto', () async {
      final calls = <(String, int, Duration)>[];
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: (host, port, timeout) async {
          calls.add((host, port, timeout));
          return true;
        },
        identify: _identifyFrom(const {}),
      );

      expect(await scanner.probe('192.168.1.9'), isTrue);
      expect(calls.single, ('192.168.1.9', 9100, const Duration(seconds: 3)));
    });

    test('probe con puerto explícito y resultado false', () async {
      final calls = <(String, int)>[];
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: (host, port, timeout) async {
          calls.add((host, port));
          return false;
        },
        identify: _identifyFrom(const {}),
      );

      expect(await scanner.probe('10.0.0.8', port: 6101), isFalse);
      expect(calls.single, ('10.0.0.8', 6101));
    });

    test('localNetworks filtra y ordena las interfaces del seam', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => const [
          NetworkInterfaceInfo(name: 'rmnet0', ip: '10.1.1.1'),
          NetworkInterfaceInfo(name: 'eth0', ip: '10.0.0.7'),
          NetworkInterfaceInfo(name: 'wlan0', ip: _ownIp),
        ],
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
      );

      final nets = await scanner.localNetworks();

      expect(nets.map((n) => n.interfaceName), ['wlan0', 'eth0']);
    });
  });

  group('WifiPrinterScanner.scan — máscara real', () {
    test('/22: barre la subred completa (1021 hosts sin la propia)', () async {
      final probe = _FakeProbe();
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => const [
          NetworkInterfaceInfo(
            name: 'wlan0',
            ip: '10.168.50.17',
            prefixLength: 22,
          ),
        ],
        probe: probe.call,
        identify: _identifyFrom(const {}),
      );

      final last = await scanner.scan().last;

      expect(last.total, 1021);
      expect(probe.hosts, hasLength(1021));
      expect(probe.hosts, containsAll(['10.168.48.1', '10.168.51.254']));
      expect(probe.hosts, isNot(contains('10.168.50.17')));
      expect(probe.hosts, isNot(contains('10.168.48.0')));
      expect(probe.hosts, isNot(contains('10.168.51.255')));
      expect(last.networkLabels, ['10.168.48.0/22']);
      expect(last.networks.single.isPartial, isFalse);
    });

    test('/16: barre solo el /22 de la IP del teléfono y lo indica', () async {
      final probe = _FakeProbe();
      final scanner = WifiPrinterScanner(
        listInterfaces: () async => const [
          NetworkInterfaceInfo(
            name: 'wlan0',
            ip: '10.168.50.17',
            prefixLength: 16,
          ),
        ],
        probe: probe.call,
        identify: _identifyFrom(const {}),
      );

      final last = await scanner.scan().last;

      expect(last.total, 1021);
      final cable = Ipv4Subnet.containing(Ipv4.parse('10.168.48.0')!, 22);
      expect(probe.hosts.every((h) => cable.contains(Ipv4.parse(h)!)), isTrue);
      expect(probe.hosts, isNot(contains('10.168.0.1')));
      final net = last.networks.single;
      expect(net.label, '10.168.48.0/22');
      expect(net.isPartial, isTrue);
      expect(net.fullLabel, '10.168.0.0/16');
      expect(net.added, isFalse);
    });

    test('concurrencia por defecto ~96 y probe de 700 ms', () {
      final scanner = WifiPrinterScanner();

      expect(scanner.concurrency, 96);
      expect(scanner.probeTimeout, const Duration(milliseconds: 700));
      expect(scanner.usesServiceDiscovery, isFalse);
    });
  });

  group('WifiPrinterScanner.scan — redes agregadas', () {
    Future<List<NetworkInterfaceInfo>> phone() async => const [
      NetworkInterfaceInfo(name: 'wlan0', ip: '10.168.50.17', prefixLength: 23),
    ];
    final cable = Ipv4Subnet.containing(Ipv4.parse('192.168.2.0')!, 24);

    test('barre la red agregada junto con la del teléfono', () async {
      final probe = _FakeProbe({'192.168.2.154'});
      final scanner = WifiPrinterScanner(
        listInterfaces: phone,
        probe: probe.call,
        identify: _identifyFrom(const {
          '192.168.2.154': NetworkPrinterIdentity(
            name: 'RICOH IM 550',
            isZebra: false,
          ),
        }),
        extraNetworks: () async => [cable],
      );

      final last = await scanner.scan().last;

      expect(last.total, 509 + 254);
      expect(last.networkLabels, ['10.168.50.0/23', '192.168.2.0/24']);
      expect(last.networks.last.added, isTrue);
      expect(probe.hosts, contains('192.168.2.154'));
      final hit = last.found.single;
      expect(hit.address, '192.168.2.154:9100');
      expect(hit.name, 'RICOH IM 550');
      expect(hit.source, WifiHitSource.addedNetwork);
      expect(hit.isKnownNonZebra, isTrue);
    });

    test(
      'red agregada igual a la del teléfono no se barre dos veces',
      () async {
        final probe = _FakeProbe();
        final scanner = WifiPrinterScanner(
          listInterfaces: _wlan,
          probe: probe.call,
          identify: _identifyFrom(const {}),
          extraNetworks: () async => [
            Ipv4Subnet.containing(Ipv4.parse(_ownIp)!, 24),
          ],
        );

        final last = await scanner.scan().last;

        expect(last.total, 253);
        expect(probe.hosts.toSet(), hasLength(253));
        expect(last.networkLabels, ['192.168.1.0/24']);
      },
    );

    test('red agregada que se solapa: cada host una sola vez', () async {
      final probe = _FakeProbe();
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {}),
        extraNetworks: () async => [
          Ipv4Subnet.containing(Ipv4.parse('192.168.0.0')!, 23),
        ],
      );

      final last = await scanner.scan().last;

      expect(probe.hosts.length, probe.hosts.toSet().length);
      // 253 del /24 + 192.168.0.1–.255 + 192.168.1.0: en el /23 la .1.0 es
      // un host válido (solo 192.168.0.0 y 192.168.1.255 son red/broadcast).
      // El resto de 192.168.1.x ya estaba.
      expect(last.total, 253 + 255 + 1);
      expect(probe.hosts, contains('192.168.1.0'));
      expect(probe.hosts, isNot(contains(_ownIp)));
    });

    test('lector de redes que falla -> solo la red del teléfono', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
        extraNetworks: () async => throw StateError('almacén'),
      );

      final last = await scanner.scan().last;

      expect(last.error, isNull);
      expect(last.networkLabels, ['192.168.1.0/24']);
    });
  });

  group('WifiPrinterScanner.scan — mDNS/Bonjour', () {
    const ricoh = MdnsService(
      name: 'RICOH IM 550 [A1B2C3]',
      type: '_pdl-datastream._tcp',
      host: '192.168.2.154',
      port: 9100,
      txt: {'product': '(RICOH IM 550)'},
    );

    test(
      'servicio en otra subred con 9100 abierto -> hit con su nombre',
      () async {
        final calls = <(List<String>, Duration)>[];
        final probe = _FakeProbe({'192.168.2.154'});
        final scanner = WifiPrinterScanner(
          listInterfaces: _wlan,
          probe: probe.call,
          identify: _identifyFrom(const {}),
          discoverServices: (types, timeout) async {
            calls.add((types, timeout));
            return const [ricoh];
          },
        );

        final last = await scanner.scan().last;

        expect(calls.single.$1, [
          '_pdl-datastream._tcp',
          '_printer._tcp',
          '_ipp._tcp',
        ]);
        expect(calls.single.$2, const Duration(seconds: 4));
        final hit = last.found.single;
        expect(hit.address, '192.168.2.154:9100');
        expect(hit.name, 'RICOH IM 550 [A1B2C3]');
        expect(hit.isZebra, isFalse);
        expect(hit.source, WifiHitSource.mdns);
      },
    );

    test('Zebra por TXT con el puerto anunciado de _pdl-datastream', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe({'192.168.1.30'}).call,
        identify: _identifyFrom(const {}),
        discoverServices: (types, timeout) async => const [
          MdnsService(
            name: 'Etiquetas andén',
            type: '_pdl-datastream._tcp',
            host: '192.168.1.30',
            port: 6101,
            txt: {'ty': 'Zebra ZD421'},
          ),
        ],
      );

      final last = await scanner.scan().last;

      // El barrido lo encontró en el 9100 (sin nombre) y mDNS en el 6101.
      final mdnsHit = last.found.firstWhere((h) => h.port == 6101);
      expect(mdnsHit.isZebra, isTrue);
      expect(mdnsHit.name, 'Etiquetas andén');
      expect(last.found.first, same(mdnsHit)); // Zebra primero
    });

    test('servicio con el puerto cerrado no es un hit', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
        discoverServices: (types, timeout) async => const [ricoh],
      );

      final last = await scanner.scan().last;

      expect(last.found, isEmpty);
      expect(last.error, isNull);
    });

    test(
      'mismo host por barrido y mDNS: un hit, gana el nombre mDNS',
      () async {
        final scanner = WifiPrinterScanner(
          listInterfaces: _wlan,
          probe: _FakeProbe({'192.168.1.9'}).call,
          identify: _identifyFrom(const {
            '192.168.1.9': NetworkPrinterIdentity(
              name: 'Web Image Monitor',
              isZebra: false,
            ),
          }),
          discoverServices: (types, timeout) async => const [
            MdnsService(
              name: 'RICOH IM 550',
              type: '_ipp._tcp',
              host: '192.168.1.9',
              port: 631,
            ),
          ],
        );

        final last = await scanner.scan().last;

        final hit = last.found.single;
        expect(hit.address, '192.168.1.9:9100');
        expect(hit.name, 'RICOH IM 550');
      },
    );

    test('hosts IPv6 se omiten', () async {
      final probe = _FakeProbe({'fe80::1'});
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {}),
        discoverServices: (types, timeout) async => const [
          MdnsService(name: 'X', type: '_ipp._tcp', host: 'fe80::1', port: 1),
        ],
      );

      final last = await scanner.scan().last;

      expect(last.found, isEmpty);
      expect(probe.hosts, isNot(contains('fe80::1')));
    });

    test('mDNS que falla se omite sin error', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe({'192.168.1.9'}).call,
        identify: _identifyFrom(const {}),
        discoverServices: (types, timeout) async => throw StateError('nsd'),
      );

      final last = await scanner.scan().last;

      expect(last.error, isNull);
      expect(last.found.single.host, '192.168.1.9');
    });

    test('indica "también buscando" hasta que termina mDNS', () async {
      final gate = Completer<List<MdnsService>>();
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
        discoverServices: (types, timeout) => gate.future,
      );
      final events = <WifiScanProgress>[];
      final done = Completer<void>();
      scanner.scan().listen(events.add, onDone: done.complete);

      // El barrido termina pero la búsqueda sigue esperando a mDNS.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events.last.scanned, 253);
      expect(events.last.done, isFalse);
      expect(events.last.discoveringServices, isTrue);

      gate.complete(const []);
      await done.future;
      expect(events.last.done, isTrue);
      expect(events.last.discoveringServices, isFalse);
    });
  });

  group('WifiPrinterScanner.scan — WS-Discovery', () {
    test('host que responde y acepta el 9100 -> hit identificado', () async {
      final calls = <(Duration, List<String>)>[];
      final probe = _FakeProbe({'192.168.2.154'});
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: probe.call,
        identify: _identifyFrom(const {
          '192.168.2.154': NetworkPrinterIdentity(
            name: 'RICOH IM 550',
            isZebra: false,
          ),
        }),
        wsDiscover: (listen, broadcasts) async {
          calls.add((listen, broadcasts));
          return ['192.168.2.154', _ownIp, 'basura', '192.168.2.154'];
        },
      );

      final last = await scanner.scan().last;

      expect(calls.single.$1, const Duration(seconds: 3));
      expect(calls.single.$2, ['192.168.1.255']);
      final hit = last.found.single;
      expect(hit.address, '192.168.2.154:9100');
      expect(hit.name, 'RICOH IM 550');
      expect(hit.source, WifiHitSource.wsd);
      // Repetido en la respuesta: se prueba una sola vez.
      expect(probe.hosts.where((h) => h == '192.168.2.154'), hasLength(1));
      // La IP propia no se prueba por WSD (tampoco la barre el barrido).
      expect(probe.hosts, isNot(contains(_ownIp)));
    });

    test('host ya encontrado por el barrido no se duplica', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe({'192.168.1.9'}).call,
        identify: _identifyFrom(const {}),
        wsDiscover: (listen, broadcasts) async {
          // Responde después de que el barrido ya lo encontró.
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return ['192.168.1.9'];
        },
      );

      final last = await scanner.scan().last;

      expect(last.found, hasLength(1));
      expect(last.found.single.source, WifiHitSource.sweep);
    });

    test('WSD que falla se omite sin error', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        probe: _FakeProbe().call,
        identify: _identifyFrom(const {}),
        wsDiscover: (listen, broadcasts) async =>
            throw const SocketException('sin UDP'),
      );

      final last = await scanner.scan().last;

      expect(last.done, isTrue);
      expect(last.error, isNull);
    });
  });

  group('WifiPrinterScanner.diagnose', () {
    SocketException errno(int code) =>
        SocketException('fallo', osError: OSError('x', code));

    PrinterReachability map(Object e) =>
        WifiPrinterScanner.reachabilityFromError(e);

    test('rechazado: ECONNREFUSED (Android, Windows, iOS)', () {
      for (final code in [111, 10061, 61]) {
        expect(map(errno(code)), PrinterReachability.refused, reason: '$code');
      }
    });

    test('sin ruta: EHOSTUNREACH / ENETUNREACH', () {
      for (final code in [113, 101, 10065, 10051, 65, 51]) {
        expect(map(errno(code)), PrinterReachability.noRoute, reason: '$code');
      }
    });

    test('timeout: sin osError, ETIMEDOUT u otro error', () {
      expect(map(errno(110)), PrinterReachability.timeout);
      expect(map(errno(10060)), PrinterReachability.timeout);
      expect(
        map(const SocketException('Connection timed out')),
        PrinterReachability.timeout,
      );
      expect(map(TimeoutException('t')), PrinterReachability.timeout);
    });

    test('inválido: host que no resuelve o argumento inválido', () {
      expect(
        map(
          const SocketException(
            'Failed host lookup: impresora',
            osError: OSError('No address associated with hostname', 7),
          ),
        ),
        PrinterReachability.invalid,
      );
      expect(map(ArgumentError('host')), PrinterReachability.invalid);
    });

    test('delega en el seam con 3 s', () async {
      final calls = <(String, int, Duration)>[];
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        diagnoser: (host, port, timeout) async {
          calls.add((host, port, timeout));
          return PrinterReachability.refused;
        },
      );

      expect(
        await scanner.diagnose(' 192.168.2.154 ', port: 9100),
        PrinterReachability.refused,
      );
      expect(calls.single, ('192.168.2.154', 9100, const Duration(seconds: 3)));
    });

    test('seam que lanza SocketException -> se clasifica', () async {
      final scanner = WifiPrinterScanner(
        listInterfaces: _wlan,
        diagnoser: (host, port, timeout) async => throw errno(113),
      );

      expect(
        await scanner.diagnose('192.168.2.154'),
        PrinterReachability.noRoute,
      );
    });

    test(
      'host vacío o puerto fuera de rango -> invalid sin conectar',
      () async {
        var called = false;
        final scanner = WifiPrinterScanner(
          listInterfaces: _wlan,
          diagnoser: (host, port, timeout) async {
            called = true;
            return PrinterReachability.reachable;
          },
        );

        expect(await scanner.diagnose(' '), PrinterReachability.invalid);
        expect(
          await scanner.diagnose('10.0.0.1', port: 0),
          PrinterReachability.invalid,
        );
        expect(
          await scanner.diagnose('10.0.0.1', port: 70000),
          PrinterReachability.invalid,
        );
        expect(called, isFalse);
      },
    );
  });
}
