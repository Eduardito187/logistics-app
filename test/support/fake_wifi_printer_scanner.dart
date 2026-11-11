import 'dart:async';

import 'package:logistics_app/core/printing/local_network.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/printing/printer_reachability.dart';
import 'package:logistics_app/core/printing/wifi_printer_scanner.dart';
import 'package:logistics_app/core/printing/wifi_scan_progress.dart';

/// Escáner WiFi falso: el test controla el stream (nunca hay red) y sabe si
/// la búsqueda arrancó o se canceló.
class FakeWifiPrinterScanner extends WifiPrinterScanner {
  FakeWifiPrinterScanner({this.reachability = PrinterReachability.reachable});

  /// Resultado de "Probar conexión".
  final PrinterReachability reachability;

  StreamController<WifiScanProgress>? controller;
  int scans = 0;
  bool cancelled = false;

  @override
  Stream<WifiScanProgress> scan({int port = kDefaultWifiPort}) {
    scans++;
    cancelled = false;
    controller = StreamController<WifiScanProgress>(
      onCancel: () => cancelled = true,
    );
    return controller!.stream;
  }

  void emit(WifiScanProgress progress) => controller!.add(progress);

  @override
  Future<List<LocalNetwork>> localNetworks() async => const [];

  @override
  Future<PrinterReachability> diagnose(
    String host, {
    int port = kDefaultWifiPort,
  }) async => reachability;
}
