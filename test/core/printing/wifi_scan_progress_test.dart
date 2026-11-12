import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/scanned_network.dart';
import 'package:logistics_app/core/printing/wifi_printer_hit.dart';
import 'package:logistics_app/core/printing/wifi_scan_progress.dart';

// WifiScanProgress: avance de la búsqueda (barra de progreso y estado).

void main() {
  group('WifiScanProgress.starting', () {
    test('en curso, sin total y barra indeterminada', () {
      const p = WifiScanProgress.starting();

      expect(p.scanned, 0);
      expect(p.total, 0);
      expect(p.found, isEmpty);
      expect(p.networks, isEmpty);
      expect(p.done, isFalse);
      expect(p.isRunning, isTrue);
      expect(p.error, isNull);
      expect(p.fraction, isNull);
    });
  });

  group('WifiScanProgress.failed', () {
    test('terminado, con el error y sin resultados', () {
      const p = WifiScanProgress.failed('Sin WiFi');

      expect(p.done, isTrue);
      expect(p.isRunning, isFalse);
      expect(p.error, 'Sin WiFi');
      expect(p.found, isEmpty);
      expect(p.networks, isEmpty);
      expect(p.fraction, isNull);
    });
  });

  group('WifiScanProgress — avance', () {
    test('fraction = scanned / total', () {
      const p = WifiScanProgress(
        scanned: 64,
        total: 256,
        found: [],
        networks: [ScannedNetwork(label: '192.168.1.0/24')],
      );

      expect(p.fraction, 0.25);
      expect(p.isRunning, isTrue);
      expect(p.error, isNull);
    });

    test('total 0 -> fraction null (indeterminada)', () {
      const p = WifiScanProgress(scanned: 0, total: 0, found: [], networks: []);

      expect(p.fraction, isNull);
    });

    test('barrido completo: fraction 1 y no está en curso', () {
      const p = WifiScanProgress(
        scanned: 253,
        total: 253,
        found: [WifiPrinterHit(host: '192.168.1.9', port: 9100)],
        networks: [ScannedNetwork(label: '192.168.1.0/24')],
        done: true,
      );

      expect(p.fraction, 1.0);
      expect(p.isRunning, isFalse);
      expect(p.found.single.host, '192.168.1.9');
    });
  });

  group('WifiScanProgress — redes y servicios', () {
    const p = WifiScanProgress(
      scanned: 10,
      total: 100,
      found: [WifiPrinterHit(host: '10.168.48.9', port: 9100)],
      networks: [
        ScannedNetwork(label: '10.168.48.0/22', fullLabel: '10.168.0.0/16'),
        ScannedNetwork(label: '192.168.2.0/24', added: true),
      ],
      discoveringServices: true,
    );

    test('networkLabels lista los rangos barridos', () {
      expect(p.networkLabels, ['10.168.48.0/22', '192.168.2.0/24']);
      expect(p.networks.first.isPartial, isTrue);
      expect(p.networks.last.isPartial, isFalse);
      expect(p.networks.last.added, isTrue);
    });

    test('stopped: terminado, conserva lo encontrado y deja de buscar', () {
      final s = p.stopped();

      expect(s.done, isTrue);
      expect(s.isRunning, isFalse);
      expect(s.discoveringServices, isFalse);
      expect(s.found.single.host, '10.168.48.9');
      expect(s.networks, p.networks);
      expect(s.scanned, 10);
      expect(s.total, 100);
    });

    test('starting/failed no están buscando servicios', () {
      expect(const WifiScanProgress.starting().discoveringServices, isFalse);
      expect(const WifiScanProgress.failed('x').discoveringServices, isFalse);
    });
  });
}
