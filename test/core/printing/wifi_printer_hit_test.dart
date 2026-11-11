import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/wifi_hit_source.dart';
import 'package:logistics_app/core/printing/wifi_printer_hit.dart';

// WifiPrinterHit: impresora encontrada por la búsqueda automática. Formato de
// dirección, nombre visible, config persistible y orden de la lista.

void main() {
  group('WifiPrinterHit — campos derivados', () {
    test('address es ip:puerto', () {
      const hit = WifiPrinterHit(host: '192.168.1.9', port: 9100);

      expect(hit.address, '192.168.1.9:9100');
    });

    test('displayName usa el nombre identificado', () {
      const hit = WifiPrinterHit(
        host: '192.168.1.9',
        port: 9100,
        name: 'Zebra ZD421',
        isZebra: true,
      );

      expect(hit.displayName, 'Zebra ZD421');
    });

    test('displayName genérico sin nombre', () {
      const hit = WifiPrinterHit(host: '192.168.1.9', port: 9100);

      expect(hit.displayName, 'Impresora de red');
      expect(hit.isZebra, isFalse);
    });
  });

  group('WifiPrinterHit.toConfig', () {
    test('con nombre: WiFi, ip:puerto y label = nombre', () {
      const hit = WifiPrinterHit(
        host: '192.168.1.9',
        port: 6101,
        name: 'Zebra ZD421',
        isZebra: true,
      );

      expect(
        hit.toConfig(),
        const PrinterConfig(
          transport: PrinterTransport.wifi,
          address: '192.168.1.9:6101',
          label: 'Zebra ZD421',
        ),
      );
    });

    test('sin nombre: label = "WiFi <ip>" (como el ingreso manual)', () {
      const hit = WifiPrinterHit(host: '10.0.0.7', port: 9100);

      final config = hit.toConfig();

      expect(config.label, 'WiFi 10.0.0.7');
      expect(config.address, '10.0.0.7:9100');
      expect(config.wifiHost, '10.0.0.7');
      expect(config.wifiPort, 9100);
    });
  });

  group('WifiPrinterHit.compare', () {
    const zebra = WifiPrinterHit(
      host: '192.168.1.200',
      port: 9100,
      name: 'Zebra ZT230',
      isZebra: true,
    );
    const named = WifiPrinterHit(
      host: '192.168.1.3',
      port: 9100,
      name: 'HP LaserJet',
    );
    const anon9 = WifiPrinterHit(host: '192.168.1.9', port: 9100);
    const anon10 = WifiPrinterHit(host: '192.168.1.10', port: 9100);

    test('Zebra antes que no Zebra', () {
      expect(WifiPrinterHit.compare(zebra, named), lessThan(0));
      expect(WifiPrinterHit.compare(named, zebra), greaterThan(0));
    });

    test('identificada antes que sin nombre', () {
      expect(WifiPrinterHit.compare(named, anon9), lessThan(0));
      expect(WifiPrinterHit.compare(anon9, named), greaterThan(0));
    });

    test('a igualdad, por IP numérica: .9 antes que .10', () {
      expect(WifiPrinterHit.compare(anon9, anon10), lessThan(0));
      expect(WifiPrinterHit.compare(anon10, anon9), greaterThan(0));
    });

    test('misma IP -> 0', () {
      expect(WifiPrinterHit.compare(anon9, anon9), 0);
    });

    test('compara los cuatro octetos, no solo el último', () {
      const a = WifiPrinterHit(host: '10.0.0.250', port: 9100);
      const b = WifiPrinterHit(host: '10.0.1.2', port: 9100);

      expect(WifiPrinterHit.compare(a, b), lessThan(0));
    });

    test('ordenar una lista: Zebra, identificadas, luego por IP', () {
      final list = [anon10, named, anon9, zebra]..sort(WifiPrinterHit.compare);

      expect(list.map((h) => h.host), [
        '192.168.1.200',
        '192.168.1.3',
        '192.168.1.9',
        '192.168.1.10',
      ]);
    });

    test('dos Zebra identificadas se ordenan por IP', () {
      const z1 = WifiPrinterHit(
        host: '192.168.1.20',
        port: 9100,
        name: 'Zebra B',
        isZebra: true,
      );
      const z2 = WifiPrinterHit(
        host: '192.168.1.4',
        port: 9100,
        name: 'Zebra A',
        isZebra: true,
      );

      expect(WifiPrinterHit.compare(z2, z1), lessThan(0));
    });
  });

  group('WifiPrinterHit — no Zebra y merge', () {
    test('isKnownNonZebra solo si tiene nombre y no es Zebra', () {
      expect(
        const WifiPrinterHit(host: 'a', port: 1, name: 'RICOH').isKnownNonZebra,
        isTrue,
      );
      expect(
        const WifiPrinterHit(
          host: 'a',
          port: 1,
          name: 'ZD421',
          isZebra: true,
        ).isKnownNonZebra,
        isFalse,
      );
      expect(
        const WifiPrinterHit(host: 'a', port: 1).isKnownNonZebra,
        isFalse,
      );
    });

    test('origen por defecto: barrido', () {
      expect(
        const WifiPrinterHit(host: 'a', port: 1).source,
        WifiHitSource.sweep,
      );
    });

    test('merge: el nombre mDNS gana sobre el título web', () {
      const sweep = WifiPrinterHit(
        host: '192.168.1.9',
        port: 9100,
        name: 'Web Image Monitor',
      );
      const mdns = WifiPrinterHit(
        host: '192.168.1.9',
        port: 9100,
        name: 'RICOH IM 550',
        source: WifiHitSource.mdns,
      );

      final merged = sweep.merge(mdns);

      expect(merged.name, 'RICOH IM 550');
      expect(merged.source, WifiHitSource.sweep);
      expect(mdns.merge(sweep).name, 'RICOH IM 550');
    });

    test('merge: completa el nombre que falta y suma Zebra', () {
      const anon = WifiPrinterHit(host: '10.0.0.2', port: 9100);
      const named = WifiPrinterHit(
        host: '10.0.0.2',
        port: 9100,
        name: 'ZD421',
        isZebra: true,
        source: WifiHitSource.wsd,
      );

      final merged = anon.merge(named);

      expect(merged.name, 'ZD421');
      expect(merged.isZebra, isTrue);
      expect(merged.address, '10.0.0.2:9100');
    });
  });
}
