import '../ipp/ipp_client.dart';
import '../print_outcome.dart';
import '../printer_config_data.dart';
import '../printer_credentials.dart';
import '../printer_exception.dart';
import '../printer_protocol.dart';
import '../raw_tcp_sender.dart';
import 'label_raster.dart';
import 'pdf_direct_job_writer.dart';

/// Puerto RAW/JetDirect estándar (impresión cruda, sin confirmación).
const int kRawPrinterPort = 9100;

/// Imprime una etiqueta ya dibujada en una impresora de OFICINA (láser/tinta):
/// - IPP: PDF o PWG raster, con autenticación y confirmación del trabajo.
/// - 9100: PCL 5 con cabecera PJL (usuario, código de usuario Ricoh); sin
///   confirmación posible.
class OfficePrinter {
  OfficePrinter({IppClient? ipp, RawTcpSender? raw})
    : _ipp = ipp ?? IppClient(),
      _raw = raw ?? sendRawTcp;

  final IppClient _ipp;
  final RawTcpSender _raw;

  Future<PrintOutcome> print(
    PrinterConfig config,
    LabelRaster raster, {
    required String jobName,
    required String userName,
    PrinterCredentials? credentials,
  }) async {
    switch (config.protocol) {
      case PrinterProtocol.ipp:
        try {
          return await _printIpp(
            config,
            raster,
            jobName: jobName,
            userName: userName,
            credentials: credentials,
          );
        } on PrinterException catch (e) {
          // La impresora aceptó el trabajo y lo canceló en el equipo (Ricoh con
          // autenticación de usuario por IPP). Si hay código de usuario, se
          // reintenta por 9100 con la cabecera PCL (USERCODE), que esa Ricoh
          // SÍ acepta. Sin código no hay a dónde caer: se propaga el motivo.
          if (e.cancelledAtDevice && (credentials?.hasUserCode ?? false)) {
            // El trabajo RAW va al puerto JetDirect 9100, no al de IPP (631).
            return _printRaw(
              config,
              raster,
              port: kRawPrinterPort,
              jobName: jobName,
              userName: userName,
              credentials: credentials,
            );
          }
          rethrow;
        }
      case PrinterProtocol.raw9100:
        return _printRaw(
          config,
          raster,
          port: config.wifiPort,
          jobName: jobName,
          userName: userName,
          credentials: credentials,
        );
    }
  }

  Future<PrintOutcome> _printIpp(
    PrinterConfig config,
    LabelRaster raster, {
    required String jobName,
    required String userName,
    PrinterCredentials? credentials,
  }) async {
    final connection = await _ipp.connect(
      config.wifiHost,
      userName: userName,
      path: config.ippPath,
      port: config.ippPort,
      tls: config.ippTls,
      credentials: credentials,
    );
    if (connection.info.isAcceptingJobs == false) {
      final problem = connection.info.problem;
      throw PrinterException(
        'La impresora no está aceptando trabajos.'
        '${problem == null ? '' : ' $problem'}',
      );
    }
    return _ipp.printRaster(
      connection,
      raster,
      jobName: jobName,
      userName: userName,
      credentials: credentials,
    );
  }

  Future<PrintOutcome> _printRaw(
    PrinterConfig config,
    LabelRaster raster, {
    required int port,
    required String jobName,
    required String userName,
    PrinterCredentials? credentials,
  }) async {
    // PDF directo (no PCL): la Ricoh IM 550 imprime el PDF por 9100, pero el
    // PCL5 crudo le salía EN BLANCO (verificado en equipo, nov 2026). Las MFP
    // de oficina modernas soportan PDF Direct Print.
    final bytes = PdfDirectJobWriter.build(
      raster,
      jobName: jobName,
      userName: userName,
      credentials: credentials,
    );
    await _raw(config.wifiHost, port, bytes);
    // Con "Impresión bloqueada" el trabajo queda retenido y se libera en el
    // panel; el 9100 no confirma, pero el resultado es claro para el operario.
    // Sin bloqueo, se envió (la impresora no confirma por 9100).
    return (credentials?.hasSecureToken ?? false)
        ? const PrintOutcome.held()
        : const PrintOutcome.sentUnconfirmed();
  }
}
