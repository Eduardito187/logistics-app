import 'package:logistics_app/core/printing/printer_detection.dart';
import 'package:logistics_app/core/printing/printer_profile_detector.dart';

/// Detector de tipo de impresora sin red: devuelve [result] y registra los
/// hosts consultados.
class FakePrinterProfileDetector extends PrinterProfileDetector {
  FakePrinterProfileDetector([this.result = PrinterDetection.unknown]);

  final PrinterDetection result;
  final List<String> hosts = [];

  @override
  Future<PrinterDetection> detect(
    String host, {
    String userName = 'distrack',
  }) async {
    hosts.add(host);
    return result;
  }
}
