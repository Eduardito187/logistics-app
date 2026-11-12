import 'dart:typed_data';

/// Etiqueta (o página) ya dibujada, en escala de grises de 8 bits.
///
/// [pixels] va fila por fila, `width * height` bytes, 0 = negro y 255 =
/// blanco. [dpi] dice el tamaño físico: `width / dpi` pulgadas de ancho.
/// Es la entrada común de PDF, PWG raster y PCL (todo Dart puro).
class LabelRaster {
  LabelRaster({
    required this.width,
    required this.height,
    required this.dpi,
    required this.pixels,
  }) : assert(width > 0 && height > 0 && dpi > 0),
       assert(pixels.length == width * height);

  /// Convierte RGBA de 8 bits (como `ui.ImageByteFormat.rawRgba`) a gris,
  /// componiendo la transparencia sobre papel blanco.
  factory LabelRaster.fromRgba(
    Uint8List rgba, {
    required int width,
    required int height,
    required double dpi,
  }) {
    final gray = Uint8List(width * height);
    for (var i = 0, p = 0; i < gray.length; i++, p += 4) {
      final r = rgba[p];
      final g = rgba[p + 1];
      final b = rgba[p + 2];
      final a = rgba[p + 3];
      // Luminancia Rec. 601 en enteros.
      final luma = (r * 299 + g * 587 + b * 114) ~/ 1000;
      gray[i] = (luma * a + 255 * (255 - a)) ~/ 255;
    }
    return LabelRaster(width: width, height: height, dpi: dpi, pixels: gray);
  }

  final int width;
  final int height;
  final double dpi;
  final Uint8List pixels;

  /// Ancho físico en puntos PDF (1/72").
  double get widthPoints => width / dpi * 72;

  /// Alto físico en puntos PDF (1/72").
  double get heightPoints => height / dpi * 72;

  /// Gris del píxel (x, y); fuera de rango = blanco.
  int at(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return 255;
    return pixels[y * width + x];
  }
}
