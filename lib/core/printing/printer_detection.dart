import 'ipp/ipp_endpoint.dart';
import 'printer_config_data.dart';
import 'printer_language.dart';
import 'printer_protocol.dart';

/// Qué se averiguó de una impresora WiFi SIN mandarle nada al 9100 (solo IPP
/// Get-Printer-Attributes y su página web).
class PrinterDetection {
  const PrinterDetection({
    this.ippEndpoint,
    this.ippAvailable = false,
    this.makeAndModel,
    this.documentFormats = const [],
    this.requiresCredentials = false,
    this.needsUserCode = false,
    this.isZebra = false,
    this.language,
    this.protocol,
  });

  /// Ruta IPP que respondió (si se pudo leer sin credenciales).
  final IppEndpoint? ippEndpoint;

  /// La impresora habla IPP (aunque haya pedido autenticación).
  final bool ippAvailable;

  final String? makeAndModel;
  final List<String> documentFormats;

  /// Pide usuario/contraseña (HTTP 401 o `uri-authentication-supported`).
  final bool requiresCredentials;

  /// Ricoh con autenticación por código de usuario: imprime por 9100 con el
  /// `USERCODE`. La UI pide el código (no contraseña).
  final bool needsUserCode;

  final bool isZebra;

  /// Perfil sugerido; `null` = no se pudo saber (se deja como está).
  final PrinterLanguage? language;
  final PrinterProtocol? protocol;

  /// Nada identificado.
  static const PrinterDetection unknown = PrinterDetection();

  bool get identified => language != null;

  /// Resumen para el operario (español).
  String get summary {
    final model = makeAndModel;
    if (!identified) {
      return 'No se pudo identificar el tipo de impresora. Elegilo abajo.';
    }
    final name = model ?? 'La impresora';
    if (language == PrinterLanguage.zpl) {
      return '$name: etiquetas Zebra (ZPL).';
    }
    final via = protocol == PrinterProtocol.ipp
        ? 'impresora de oficina por IPP'
        : 'impresora de oficina por el puerto 9100 (PCL)';
    final auth = requiresCredentials
        ? ' Pide usuario y contraseña: completá el acceso.'
        : needsUserCode
        ? ' Pide tu código de usuario: completalo abajo.'
        : '';
    return '$name: $via.$auth';
  }

  /// [config] con el perfil detectado (si se identificó).
  PrinterConfig applyTo(PrinterConfig config) {
    final lang = language;
    if (lang == null) return config;
    final proto = protocol ?? PrinterProtocol.raw9100;
    final endpoint = ippEndpoint;
    return config.copyWith(
      language: lang,
      protocol: proto,
      ippPath: proto == PrinterProtocol.ipp ? endpoint?.path : null,
      ippPort: proto == PrinterProtocol.ipp ? endpoint?.port : null,
      ippTls: proto == PrinterProtocol.ipp && (endpoint?.tls ?? false),
    );
  }
}
