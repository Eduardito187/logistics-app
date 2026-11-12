import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/local_network.dart';
import 'package:logistics_app/core/printing/network_interface_info.dart';

// LocalNetwork.fromInterfaces: de las interfaces IPv4 del sistema se queda
// solo con las redes WiFi/LAN privadas, sin datos móviles ni VPN, WiFi primero
// y sin repetir el mismo rango. Con la máscara real calcula qué se barre.

NetworkInterfaceInfo _i(String name, String ip, [int prefix = 24]) =>
    NetworkInterfaceInfo(name: name, ip: ip, prefixLength: prefix);

void main() {
  group('LocalNetwork.fromInterfaces — IPs privadas', () {
    test('acepta 10/8, 172.16/12 y 192.168/16', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('wlan0', '192.168.1.20'),
        _i('eth0', '10.0.0.5'),
        _i('en1', '172.16.4.9'),
        _i('en2', '172.31.200.1'),
      ]);

      expect(
        nets.map((n) => n.label),
        unorderedEquals([
          '192.168.1.0/24',
          '10.0.0.0/24',
          '172.16.4.0/24',
          '172.31.200.0/24',
        ]),
      );
    });

    test('descarta IPs públicas y los bordes fuera de 172.16/12', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('wlan0', '8.8.8.8'),
        _i('wlan1', '100.64.0.1'),
        _i('eth0', '172.15.0.1'),
        _i('eth1', '172.32.0.1'),
        _i('eth2', '192.169.0.1'),
      ]);

      expect(nets, isEmpty);
    });

    test('descarta IPs mal formadas o no IPv4', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('wlan0', '192.168.1'),
        _i('wlan1', '192.168.1.300'),
        _i('wlan2', 'abc'),
        _i('wlan3', 'fe80::1'),
        _i('wlan4', '192.168.1.2.3'),
        _i('wlan5', '192.168.-1.2'),
      ]);

      expect(nets, isEmpty);
    });

    test('lista vacía -> sin redes', () {
      expect(LocalNetwork.fromInterfaces(const []), isEmpty);
    });
  });

  group('LocalNetwork.fromInterfaces — interfaces excluidas', () {
    test('datos móviles, VPN, túneles y loopback no son la red del local', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('rmnet_data0', '10.1.1.1'),
        _i('ccmni1', '10.2.2.2'),
        _i('pdp_ip0', '10.3.3.3'),
        _i('wwan0', '10.4.4.4'),
        _i('tun0', '10.5.5.5'),
        _i('ppp0', '10.6.6.6'),
        _i('clat4', '192.168.10.1'),
        _i('v4-rmnet_data0', '192.168.11.1'),
        _i('dummy0', '192.168.12.1'),
        _i('ipsec0', '192.168.13.1'),
        _i('utun2', '172.20.0.1'),
        _i('lo', '10.7.7.7'),
      ]);

      expect(nets, isEmpty);
    });

    test('la exclusión no distingue mayúsculas', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('RMNET0', '10.1.1.1'),
        _i('Tun1', '10.2.2.2'),
        _i('WLAN0', '192.168.1.20'),
      ]);

      expect(nets.map((n) => n.interfaceName), ['WLAN0']);
    });
  });

  group('LocalNetwork.fromInterfaces — orden y duplicados', () {
    test('WiFi primero, luego Ethernet, luego el resto', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('bridge0', '192.168.50.1'),
        _i('eth0', '10.0.0.5'),
        _i('wlan0', '192.168.1.20'),
      ]);

      expect(nets.map((n) => n.interfaceName), ['wlan0', 'eth0', 'bridge0']);
    });

    test('"Wi-Fi" (nombre de Windows) cuenta como WiFi', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('Ethernet', '10.0.0.5'),
        _i('Wi-Fi', '192.168.1.20'),
      ]);

      expect(nets.first.interfaceName, 'Wi-Fi');
    });

    test('mismo rango en dos interfaces -> una sola red (la primera)', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('wlan0', '192.168.1.20'),
        _i('wlan1', '192.168.1.30'),
      ]);

      expect(nets, hasLength(1));
      expect(nets.single.interfaceName, 'wlan0');
      expect(nets.single.ownIp, '192.168.1.20');
    });

    test('mismo rango en eth y wlan -> gana wlan aunque eth venga antes', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('eth0', '192.168.1.5'),
        _i('wlan0', '192.168.1.20'),
      ]);

      expect(nets, hasLength(1));
      expect(nets.single.interfaceName, 'wlan0');
      expect(nets.single.ownIp, '192.168.1.20');
    });

    test('"lo" exacto se excluye pero "local0" con IP privada no', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('lo', '10.7.7.7'),
        _i('local0', '192.168.9.2'),
      ]);

      expect(nets.map((n) => n.interfaceName), ['local0']);
    });

    test('caso real: WiFi 10.168.50.x/23 y otra 172.30.220.x/20', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('wlan0', '10.168.50.17', 23),
        _i('eth1', '172.30.220.5', 20),
      ]);

      expect(nets.map((n) => n.label), ['10.168.50.0/23', '172.30.220.0/22']);
    });
  });

  group('LocalNetwork — máscara real', () {
    test('/24 por defecto: barre la subred completa', () {
      final net = LocalNetwork.fromInterfaces([
        _i('wlan0', '192.168.1.20'),
      ]).single;

      expect(net.interfaceName, 'wlan0');
      expect(net.ownIp, '192.168.1.20');
      expect(net.prefixLength, 24);
      expect(net.label, '192.168.1.0/24');
      expect(net.isScanLimited, isFalse);
      expect(net.scanSubnet.hostCount, 254);
    });

    test('/22: subred completa de 1022 hosts', () {
      final net = LocalNetwork.fromInterfaces([
        _i('wlan0', '10.168.50.17', 22),
      ]).single;

      expect(net.subnet.label, '10.168.48.0/22');
      expect(net.scanSubnet, net.subnet);
      expect(net.scanSubnet.hostCount, 1022);
      expect(net.isScanLimited, isFalse);
    });

    test('/23: subred completa', () {
      final net = LocalNetwork.fromInterfaces([
        _i('wlan0', '10.168.51.200', 23),
      ]).single;

      expect(net.label, '10.168.50.0/23');
      expect(net.scanSubnet.hostCount, 510);
    });

    test('/16 -> se barre el /22 que contiene la IP del teléfono', () {
      final net = LocalNetwork.fromInterfaces([
        _i('wlan0', '10.168.50.17', 16),
      ]).single;

      expect(net.subnet.label, '10.168.0.0/16');
      expect(net.isScanLimited, isTrue);
      expect(net.scanSubnet.label, '10.168.48.0/22');
      expect(net.label, '10.168.48.0/22');
      expect(net.scanSubnet.hostCount, 1022);
    });

    test('/20 -> también se limita a /22', () {
      final net = LocalNetwork.fromInterfaces([
        _i('wlan0', '172.30.220.5', 20),
      ]).single;

      expect(net.subnet.label, '172.30.208.0/20');
      expect(net.label, '172.30.220.0/22');
    });

    test('/26: subred chica de 62 hosts', () {
      final net = LocalNetwork.fromInterfaces([
        _i('wlan0', '192.168.1.70', 26),
      ]).single;

      expect(net.label, '192.168.1.64/26');
      expect(net.scanSubnet.hostCount, 62);
    });

    test('máscara inválida (0 o > 32) -> se asume /24', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('wlan0', '192.168.1.20', 0),
        _i('eth0', '10.0.0.5', 40),
      ]);

      expect(nets.map((n) => n.prefixLength), [24, 24]);
    });

    test('dos interfaces en el mismo /22 de una red /16 -> una sola', () {
      final nets = LocalNetwork.fromInterfaces([
        _i('wlan0', '10.168.50.17', 16),
        _i('eth0', '10.168.49.3', 16),
      ]);

      expect(nets, hasLength(1));
    });
  });
}
