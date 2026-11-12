/// Valor `resolution` de IPP: 9 bytes (x, y como int32 y la unidad).
class IppResolution {
  const IppResolution(this.x, this.y, {this.units = dotsPerInch});

  /// Unidad 3 = puntos por pulgada; 4 = por centímetro.
  static const int dotsPerInch = 3;
  static const int dotsPerCm = 4;

  final int x;
  final int y;
  final int units;

  /// Resolución horizontal en dpi (convierte si vino por centímetro).
  int get dpiX => units == dotsPerCm ? (x * 2.54).round() : x;

  @override
  bool operator ==(Object other) =>
      other is IppResolution &&
      other.x == x &&
      other.y == y &&
      other.units == units;

  @override
  int get hashCode => Object.hash(x, y, units);

  @override
  String toString() {
    final unit = units == dotsPerInch ? 'dpi' : 'dpcm';
    return '${x}x$y$unit';
  }
}
