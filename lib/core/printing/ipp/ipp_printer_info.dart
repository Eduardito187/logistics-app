import 'ipp_message.dart';
import 'ipp_resolution.dart';

/// Lo que la impresora dice de sí misma (respuesta de Get-Printer-Attributes).
class IppPrinterInfo {
  const IppPrinterInfo({
    this.makeAndModel,
    this.name,
    this.state,
    this.stateReasons = const [],
    this.documentFormats = const [],
    this.authenticationSupported = const [],
    this.isAcceptingJobs,
    this.pwgResolutions = const [],
    this.pwgTypes = const [],
  });

  factory IppPrinterInfo.fromMessage(IppMessage m) {
    return IppPrinterInfo(
      makeAndModel: m.attribute('printer-make-and-model')?.string,
      name: m.attribute('printer-name')?.string,
      state: m.attribute('printer-state')?.integer,
      stateReasons: m.attribute('printer-state-reasons')?.strings ?? const [],
      documentFormats:
          m.attribute('document-format-supported')?.strings ?? const [],
      authenticationSupported:
          m.attribute('uri-authentication-supported')?.strings ?? const [],
      isAcceptingJobs: _bool(m.attribute('printer-is-accepting-jobs')?.values),
      pwgResolutions:
          m
              .attribute('pwg-raster-document-resolution-supported')
              ?.values
              .whereType<IppResolution>()
              .toList() ??
          const [],
      pwgTypes:
          m.attribute('pwg-raster-document-type-supported')?.strings ??
          const [],
    );
  }

  static bool? _bool(List<Object?>? values) {
    if (values == null) return null;
    for (final v in values) {
      if (v is bool) return v;
    }
    return null;
  }

  /// printer-state: 3 = libre, 4 = imprimiendo, 5 = detenida.
  static const int stateIdle = 3;
  static const int stateProcessing = 4;
  static const int stateStopped = 5;

  final String? makeAndModel;
  final String? name;
  final int? state;
  final List<String> stateReasons;
  final List<String> documentFormats;
  final List<String> authenticationSupported;
  final bool? isAcceptingJobs;
  final List<IppResolution> pwgResolutions;
  final List<String> pwgTypes;

  /// Nombre para mostrar: modelo, nombre o genérico.
  String get displayName => makeAndModel ?? name ?? 'Impresora IPP';

  /// Pide usuario y contraseña (Basic/Digest/Kerberos) para imprimir.
  bool get requiresCredentials => authenticationSupported.any(
    (a) => a == 'basic' || a == 'digest' || a == 'negotiate',
  );

  /// Identifica al usuario solo por nombre (`requesting-user-name`).
  bool get wantsUserName =>
      authenticationSupported.contains('requesting-user-name');

  bool supports(String mime) =>
      documentFormats.any((f) => f.toLowerCase() == mime);

  /// Problema visible del estado (papel, tóner, tapa, pausa…), o `null`.
  String? get problem {
    final reasons = stateReasons
        .map((r) => r.replaceAll(RegExp(r'-(error|warning|report)$'), ''))
        .toSet();
    final parts = <String>[
      for (final entry in _reasonTexts.entries)
        if (reasons.contains(entry.key)) entry.value,
    ];
    if (parts.isEmpty && state == stateStopped) parts.add('detenida');
    return parts.isEmpty ? null : 'La impresora está ${parts.join(', ')}.';
  }

  static const Map<String, String> _reasonTexts = {
    'media-empty': 'sin papel',
    'media-needed': 'sin papel',
    'media-jam': 'con papel atascado',
    'toner-empty': 'sin tóner',
    'marker-supply-empty': 'sin tóner/tinta',
    'door-open': 'con una puerta abierta',
    'cover-open': 'con la tapa abierta',
    'paused': 'en pausa',
    'offline': 'fuera de línea',
    'shutdown': 'apagándose',
  };
}
