import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ipp/ipp_client.dart';
import 'network_printer_identity.dart';
import 'printer_detection.dart';
import 'printer_exception.dart';
import 'printer_language.dart';
import 'printer_protocol.dart';
import 'wifi_printer_scanner.dart';

/// Averigua qué tipo de impresora hay en una IP, como Windows al agregarla:
/// 1. IPP Get-Printer-Attributes (631, luego HTTPS): modelo, formatos y si
///    pide autenticación. Si responde y no es Zebra → oficina por IPP.
/// 2. Si no hay IPP: su página web (`<title>`): Zebra → ZPL; otra marca →
///    oficina por 9100 (PCL).
///
/// NUNCA manda bytes al 9100 (cualquier cosa que llegue ahí a una láser se
/// imprime como basura).
class PrinterProfileDetector {
  PrinterProfileDetector({
    IppClient? ipp,
    PrinterIdentifier? identify,
    this.identifyTimeout = const Duration(seconds: 2),
  }) : _ipp = ipp ?? IppClient(timeout: const Duration(seconds: 4)),
       _identify = identify ?? WifiPrinterScanner.identifyOverHttp;

  final IppClient _ipp;
  final PrinterIdentifier _identify;
  final Duration identifyTimeout;

  Future<PrinterDetection> detect(
    String host, {
    String userName = 'distrack',
  }) async {
    try {
      final connection = await _ipp.connect(host, userName: userName);
      final info = connection.info;
      final model = info.makeAndModel ?? info.name;
      final zebra =
          model != null && NetworkPrinterIdentity.looksLikeZebra(model);
      // Ricoh con autenticación de usuario (IPP solo admite `requesting-user-
      // name` → el equipo cancela el trabajo): se imprime por 9100 con el
      // código de usuario, que la Ricoh SÍ acepta. Verificado con una IM 550.
      final ricohUserAuth =
          !zebra &&
          model != null &&
          NetworkPrinterIdentity.looksLikeRicoh(model) &&
          info.wantsUserName &&
          !info.requiresCredentials;
      final raw9100 = zebra || ricohUserAuth;
      return PrinterDetection(
        ippEndpoint: connection.endpoint,
        ippAvailable: true,
        makeAndModel: model,
        documentFormats: info.documentFormats,
        requiresCredentials: info.requiresCredentials,
        needsUserCode: ricohUserAuth,
        isZebra: zebra,
        language: zebra ? PrinterLanguage.zpl : PrinterLanguage.office,
        protocol: raw9100 ? PrinterProtocol.raw9100 : PrinterProtocol.ipp,
      );
    } on PrinterException catch (e) {
      if (e.needsSetup) {
        // Habla IPP pero pide credenciales (HTTP 401 / not-authenticated).
        final identity = await _safeIdentify(host);
        return PrinterDetection(
          ippAvailable: true,
          makeAndModel: identity?.name,
          requiresCredentials: true,
          isZebra: identity?.isZebra ?? false,
          language: PrinterLanguage.office,
          protocol: PrinterProtocol.ipp,
        );
      }
    } on IOException {
      // Sin IPP: se sigue con la web.
    } on TimeoutException {
      // Ídem.
    }
    final identity = await _safeIdentify(host);
    if (identity == null) return PrinterDetection.unknown;
    return PrinterDetection(
      makeAndModel: identity.name,
      isZebra: identity.isZebra,
      language: identity.isZebra ? PrinterLanguage.zpl : PrinterLanguage.office,
      protocol: PrinterProtocol.raw9100,
    );
  }

  Future<NetworkPrinterIdentity?> _safeIdentify(String host) async {
    try {
      return await _identify(host, identifyTimeout);
    } on Object {
      return null;
    }
  }
}

final printerProfileDetectorProvider = Provider<PrinterProfileDetector>(
  (ref) => PrinterProfileDetector(),
);
