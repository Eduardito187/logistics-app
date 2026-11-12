import 'dart:math' as math;
import 'dart:typed_data';

import 'label_raster.dart';

/// Ubica una etiqueta en una hoja (A4 por defecto) a la resolución de la
/// impresora: tamaño físico real, centrada, achicada solo si no entra en el
/// área útil. Genera la hoja fila por fila (sin guardar la página entera en
/// memoria: A4 a 600 dpi son 35 MB en gris).
class PageLayout {
  factory PageLayout({
    required LabelRaster raster,
    required int dpi,
    double pageWidthPt = a4WidthPt,
    double pageHeightPt = a4HeightPt,
    double marginPt = 36,
  }) {
    final pageW = (pageWidthPt * dpi / 72).round();
    final pageH = (pageHeightPt * dpi / 72).round();
    final margin = (marginPt * dpi / 72).round();
    var scale = dpi / raster.dpi;
    final maxW = math.max(1, pageW - 2 * margin);
    final maxH = math.max(1, pageH - 2 * margin);
    final fit = math.min(
      maxW / (raster.width * scale),
      maxH / (raster.height * scale),
    );
    if (fit < 1) scale *= fit;
    final drawW = math.max(1, (raster.width * scale).round());
    final drawH = math.max(1, (raster.height * scale).round());
    return PageLayout._(
      raster: raster,
      dpi: dpi,
      pageWidthPt: pageWidthPt,
      pageHeightPt: pageHeightPt,
      pageWidthPx: pageW,
      pageHeightPx: pageH,
      left: (pageW - drawW) ~/ 2,
      top: (pageH - drawH) ~/ 2,
      drawWidth: drawW,
      drawHeight: drawH,
    );
  }

  PageLayout._({
    required this.raster,
    required this.dpi,
    required this.pageWidthPt,
    required this.pageHeightPt,
    required this.pageWidthPx,
    required this.pageHeightPx,
    required this.left,
    required this.top,
    required this.drawWidth,
    required this.drawHeight,
  }) : _sourceX = List<int>.generate(
         drawWidth,
         (x) => math.min(raster.width - 1, x * raster.width ~/ drawWidth),
       );

  /// A4 en puntos (1/72").
  static const double a4WidthPt = 595.28;
  static const double a4HeightPt = 841.89;

  final LabelRaster raster;
  final int dpi;
  final double pageWidthPt;
  final double pageHeightPt;
  final int pageWidthPx;
  final int pageHeightPx;

  /// Esquina y tamaño de la etiqueta dentro de la hoja (en píxeles).
  final int left;
  final int top;
  final int drawWidth;
  final int drawHeight;

  /// Columna de origen de cada columna dibujada (vecino más cercano).
  final List<int> _sourceX;

  /// `true` si la fila [y] de la hoja es toda blanca.
  bool isBlankRow(int y) => y < top || y >= top + drawHeight;

  /// Fila [y] de la hoja en gris (255 = blanco). Reusa [into] si se pasa.
  Uint8List grayRow(int y, [Uint8List? into]) {
    final row = into ?? Uint8List(pageWidthPx);
    row.fillRange(0, pageWidthPx, 255);
    if (isBlankRow(y)) return row;
    final sy = math.min(
      raster.height - 1,
      (y - top) * raster.height ~/ drawHeight,
    );
    final base = sy * raster.width;
    final pixels = raster.pixels;
    for (var x = 0; x < drawWidth; x++) {
      row[left + x] = pixels[base + _sourceX[x]];
    }
    return row;
  }
}
