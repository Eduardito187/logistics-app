import 'dart:convert';
import 'dart:typed_data';

import 'label_raster.dart';
import 'page_layout.dart';

/// PWG Raster (PWG 5102.4) de UNA página A4: sync `RaS2`, cabecera de 1796
/// bytes y las filas comprimidas (repetición de fila + PackBits por píxel).
/// Para impresoras IPP Everywhere / Mopria que no aceptan PDF.
abstract final class PwgRasterWriter {
  /// Tamaño de la cabecera de página.
  static const int headerSize = 1796;

  /// sGray (8 bits) y sRGB (24 bits), códigos de ColorSpace de PWG.
  static const int colorSpaceSGray = 18;
  static const int colorSpaceSRgb = 19;

  static Uint8List build(
    LabelRaster raster, {
    int dpi = 300,
    bool rgb = false,
  }) {
    final layout = PageLayout(raster: raster, dpi: dpi);
    final bytesPerPixel = rgb ? 3 : 1;
    final out = BytesBuilder(copy: false)
      ..add(latin1.encode('RaS2'))
      ..add(header(layout, rgb: rgb));

    final gray = Uint8List(layout.pageWidthPx);
    Uint8List? previous;
    var repeat = 0;
    for (var y = 0; y < layout.pageHeightPx; y++) {
      layout.grayRow(y, gray);
      final line = rgb ? _toRgb(gray) : Uint8List.fromList(gray);
      final prev = previous;
      if (prev != null && repeat < 255 && _equal(prev, line)) {
        repeat++;
        continue;
      }
      if (prev != null) {
        out
          ..addByte(repeat)
          ..add(encodeLine(prev, bytesPerPixel));
      }
      previous = line;
      repeat = 0;
    }
    final last = previous;
    if (last != null) {
      out
        ..addByte(repeat)
        ..add(encodeLine(last, bytesPerPixel));
    }
    return out.takeBytes();
  }

  /// Cabecera de página de 1796 bytes (big-endian, campos según PWG 5102.4).
  static Uint8List header(PageLayout layout, {bool rgb = false}) {
    final h = ByteData(headerSize);
    final bytes = h.buffer.asUint8List();
    void str(int offset, String value) {
      final b = latin1.encode(value);
      bytes.setRange(offset, offset + b.length, b);
    }

    void u32(int offset, int value) => h.setUint32(offset, value);

    final bitsPerPixel = rgb ? 24 : 8;
    str(0, 'PwgRaster');
    u32(276, layout.dpi); // HWResolution[0]
    u32(280, layout.dpi); // HWResolution[1]
    u32(340, 1); // NumCopies
    u32(352, layout.pageWidthPt.round()); // PageSize[0] en puntos
    u32(356, layout.pageHeightPt.round()); // PageSize[1]
    u32(372, layout.pageWidthPx); // Width
    u32(376, layout.pageHeightPx); // Height
    u32(384, 8); // BitsPerColor
    u32(388, bitsPerPixel); // BitsPerPixel
    u32(392, layout.pageWidthPx * bitsPerPixel ~/ 8); // BytesPerLine
    u32(396, 0); // ColorOrder = chunky
    u32(400, rgb ? colorSpaceSRgb : colorSpaceSGray); // ColorSpace
    u32(420, rgb ? 3 : 1); // NumColors
    u32(452, 1); // TotalPageCount
    u32(456, 1); // CrossFeedTransform
    u32(460, 1); // FeedTransform
    u32(464, layout.left); // ImageBoxLeft
    u32(468, layout.top); // ImageBoxTop
    u32(472, layout.left + layout.drawWidth); // ImageBoxRight
    u32(476, layout.top + layout.drawHeight); // ImageBoxBottom
    u32(480, 0x00FFFFFF); // AlternatePrimary
    str(1732, 'iso_a4_210x297mm'); // PageSizeName
    return bytes;
  }

  /// Comprime una fila: `n` 0–127 = repetir el próximo píxel n+1 veces;
  /// `n` 129–255 = siguen 257−n píxeles literales (2 a 128).
  static Uint8List encodeLine(Uint8List line, int bytesPerPixel) {
    final pixels = line.length ~/ bytesPerPixel;
    final out = BytesBuilder(copy: false);
    bool same(int a, int b) {
      for (var k = 0; k < bytesPerPixel; k++) {
        if (line[a * bytesPerPixel + k] != line[b * bytesPerPixel + k]) {
          return false;
        }
      }
      return true;
    }

    void pixel(int i) => out.add(
      Uint8List.sublistView(
        line,
        i * bytesPerPixel,
        (i + 1) * bytesPerPixel,
      ),
    );

    var i = 0;
    while (i < pixels) {
      var run = 1;
      while (i + run < pixels && run < 128 && same(i, i + run)) {
        run++;
      }
      if (run > 1) {
        out.addByte(run - 1);
        pixel(i);
        i += run;
        continue;
      }
      // Literales: hasta que empiece una repetición o se llegue a 128.
      var count = 1;
      while (i + count < pixels &&
          count < 128 &&
          !(i + count + 1 < pixels && same(i + count, i + count + 1))) {
        count++;
      }
      if (count == 1) {
        out.addByte(0);
        pixel(i);
      } else {
        out.addByte(257 - count);
        for (var k = 0; k < count; k++) {
          pixel(i + k);
        }
      }
      i += count;
    }
    return out.takeBytes();
  }

  static Uint8List _toRgb(Uint8List gray) {
    final rgb = Uint8List(gray.length * 3);
    for (var i = 0, j = 0; i < gray.length; i++, j += 3) {
      rgb[j] = gray[i];
      rgb[j + 1] = gray[i];
      rgb[j + 2] = gray[i];
    }
    return rgb;
  }

  static bool _equal(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
