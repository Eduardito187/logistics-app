import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/ipv4.dart';
import 'package:logistics_app/core/printing/ipv4_subnet.dart';

// Ipv4 / Ipv4Subnet: aritmética de direcciones para calcular el rango real de
// hosts a barrir según la máscara (dirección de red, broadcast, hosts).

int _ip(String s) => Ipv4.parse(s)!;

void main() {
  group('Ipv4', () {
    test('parse/format ida y vuelta', () {
      expect(Ipv4.format(_ip('192.168.2.154')), '192.168.2.154');
      expect(Ipv4.format(_ip('0.0.0.0')), '0.0.0.0');
      expect(Ipv4.format(_ip('255.255.255.255')), '255.255.255.255');
    });

    test('parse rechaza lo que no es IPv4', () {
      for (final bad in ['', '1.2.3', '1.2.3.4.5', '256.1.1.1', 'a.b.c.d']) {
        expect(Ipv4.parse(bad), isNull, reason: bad);
      }
      expect(Ipv4.parse('1..2.3'), isNull);
      expect(Ipv4.parse('fe80::1'), isNull);
    });

    test('isPrivate: 10/8, 172.16/12, 192.168/16', () {
      expect(Ipv4.isPrivate(_ip('10.168.50.1')), isTrue);
      expect(Ipv4.isPrivate(_ip('172.16.0.1')), isTrue);
      expect(Ipv4.isPrivate(_ip('172.31.255.1')), isTrue);
      expect(Ipv4.isPrivate(_ip('192.168.2.154')), isTrue);
      expect(Ipv4.isPrivate(_ip('172.32.0.1')), isFalse);
      expect(Ipv4.isPrivate(_ip('8.8.8.8')), isFalse);
    });
  });

  group('Ipv4Subnet', () {
    test('/24: red, broadcast, 254 hosts sin bordes', () {
      final s = Ipv4Subnet.containing(_ip('192.168.2.154'), 24);

      expect(s.label, '192.168.2.0/24');
      expect(Ipv4.format(s.network), '192.168.2.0');
      expect(Ipv4.format(s.broadcast), '192.168.2.255');
      expect(s.hostCount, 254);
      final hosts = s.hosts.toList();
      expect(hosts, hasLength(254));
      expect(Ipv4.format(hosts.first), '192.168.2.1');
      expect(Ipv4.format(hosts.last), '192.168.2.254');
    });

    test('/22: 1022 hosts de .48.1 a .51.254', () {
      final s = Ipv4Subnet.containing(_ip('10.168.50.17'), 22);

      expect(s.label, '10.168.48.0/22');
      expect(Ipv4.format(s.broadcast), '10.168.51.255');
      final hosts = s.hosts.toList();
      expect(hosts, hasLength(1022));
      expect(Ipv4.format(hosts.first), '10.168.48.1');
      expect(Ipv4.format(hosts.last), '10.168.51.254');
      expect(hosts.map(Ipv4.format), contains('10.168.49.0'));
    });

    test('/16: dirección de red y broadcast', () {
      final s = Ipv4Subnet.containing(_ip('10.168.50.17'), 16);

      expect(s.label, '10.168.0.0/16');
      expect(Ipv4.format(s.broadcast), '10.168.255.255');
      expect(s.hostCount, 65534);
    });

    test('/31 y /32 incluyen todas sus direcciones', () {
      final s31 = Ipv4Subnet.containing(_ip('192.168.1.7'), 31);
      final s32 = Ipv4Subnet.containing(_ip('192.168.1.7'), 32);

      expect(s31.hosts.map(Ipv4.format), ['192.168.1.6', '192.168.1.7']);
      expect(s32.hosts.map(Ipv4.format), ['192.168.1.7']);
      expect(s32.hostCount, 1);
    });

    test('contains', () {
      final s = Ipv4Subnet.containing(_ip('10.168.50.17'), 23);

      expect(s.contains(_ip('10.168.51.200')), isTrue);
      expect(s.contains(_ip('10.168.52.1')), isFalse);
      expect(s.contains(_ip('192.168.2.154')), isFalse);
    });

    test('igualdad por red y prefijo', () {
      expect(
        Ipv4Subnet.containing(_ip('192.168.2.1'), 24),
        Ipv4Subnet.containing(_ip('192.168.2.200'), 24),
      );
      expect(
        Ipv4Subnet.containing(_ip('192.168.2.1'), 24),
        isNot(Ipv4Subnet.containing(_ip('192.168.2.1'), 23)),
      );
    });
  });
}
