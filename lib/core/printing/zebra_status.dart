/// Estado de una Zebra leído por el puerto 9100 tras mandar la etiqueta.
///
/// Entiende las dos respuestas de ZPL:
/// - `~HS` (host status): tres líneas `<STX>…<ETX>` con banderas por coma.
/// - `~HQES`: bloque "PRINTER STATUS" con `ERRORS:` y máscaras hexadecimales.
class ZebraStatus {
  const ZebraStatus({
    this.paperOut = false,
    this.paused = false,
    this.headOpen = false,
    this.ribbonOut = false,
    this.otherError = false,
  });

  final bool paperOut;
  final bool paused;
  final bool headOpen;
  final bool ribbonOut;
  final bool otherError;

  bool get hasProblem =>
      paperOut || paused || headOpen || ribbonOut || otherError;

  /// Texto para el operario si hay problema; `null` si está lista.
  String? get problemMessage {
    if (!hasProblem) return null;
    final parts = <String>[
      if (paperOut) 'sin etiquetas/papel',
      if (headOpen) 'con el cabezal abierto',
      if (ribbonOut) 'sin cinta',
      if (paused) 'en pausa',
      if (otherError) 'con un error',
    ];
    return 'La impresora está ${parts.join(', ')}. La etiqueta quedó en '
        'espera: resolvelo y saldrá.';
  }

  /// Interpreta la respuesta cruda; `null` si no es una respuesta de estado.
  static ZebraStatus? parse(String raw) {
    if (raw.contains('PRINTER STATUS') || raw.contains('ERRORS:')) {
      return _parseHqes(raw);
    }
    return _parseHs(raw);
  }

  static ZebraStatus? _parseHs(String raw) {
    final lines = RegExp(
      '\x02([^\x03]*)\x03',
    ).allMatches(raw).map((m) => m.group(1)!.split(',')).toList();
    if (lines.isEmpty || lines.first.length < 3) return null;
    bool flag(int line, int index) =>
        lines.length > line &&
        lines[line].length > index &&
        lines[line][index].trim() == '1';
    return ZebraStatus(
      paperOut: flag(0, 1),
      paused: flag(0, 2),
      headOpen: flag(1, 2),
      ribbonOut: flag(1, 3),
    );
  }

  static ZebraStatus? _parseHqes(String raw) {
    final match = RegExp(
      r'ERRORS:\s*([01])\s+([0-9A-Fa-f]{8})\s+([0-9A-Fa-f]{8})',
    ).firstMatch(raw);
    if (match == null) return null;
    if (match.group(1) == '0') return const ZebraStatus();
    final group1 = int.parse(match.group(3)!, radix: 16);
    final paperOut = group1 & 0x1 != 0;
    final ribbonOut = group1 & 0x2 != 0;
    final headOpen = group1 & 0x4 != 0;
    final group2 = int.parse(match.group(2)!, radix: 16);
    final other = group1 & ~0x7 != 0 || group2 != 0;
    return ZebraStatus(
      paperOut: paperOut,
      ribbonOut: ribbonOut,
      headOpen: headOpen,
      otherError: other || !(paperOut || ribbonOut || headOpen),
    );
  }
}
