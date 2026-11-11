import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'label_raster.dart';
import 'page_layout.dart';

/// PDF mínimo de UNA página con la etiqueta como imagen en gris, escrito a
/// mano (sin paquetes): catálogo, páginas, página, contenido e imagen
/// `/DeviceGray` comprimida con `/FlateDecode` (zlib de dart:io), con tabla
/// xref de offsets exactos.
///
/// La hoja es A4 (lo que toda impresora de oficina acepta) con la etiqueta a
/// su tamaño físico real, centrada; se achica solo si no entra.
abstract final class PdfImageWriter {
  static Uint8List build(
    LabelRaster raster, {
    double pageWidthPt = PageLayout.a4WidthPt,
    double pageHeightPt = PageLayout.a4HeightPt,
    double marginPt = 36,
  }) {
    var w = raster.widthPoints;
    var h = raster.heightPoints;
    final fit = math.min(
      (pageWidthPt - 2 * marginPt) / w,
      (pageHeightPt - 2 * marginPt) / h,
    );
    if (fit < 1) {
      w *= fit;
      h *= fit;
    }
    final x = (pageWidthPt - w) / 2;
    final y = (pageHeightPt - h) / 2;

    final content = latin1.encode(
      'q ${_n(w)} 0 0 ${_n(h)} ${_n(x)} ${_n(y)} cm /Im1 Do Q\n',
    );
    final image = Uint8List.fromList(
      ZLibCodec(level: 6).encode(raster.pixels),
    );

    final out = BytesBuilder(copy: false);
    final offsets = <int>[];
    void ascii(String s) => out.add(latin1.encode(s));
    void obj(String body) {
      offsets.add(out.length);
      ascii('${offsets.length} 0 obj\n$body\nendobj\n');
    }

    void streamObj(String dict, List<int> data) {
      offsets.add(out.length);
      ascii('${offsets.length} 0 obj\n$dict\nstream\n');
      out.add(data);
      ascii('\nendstream\nendobj\n');
    }

    // Cabecera + comentario binario (marca el archivo como binario).
    ascii('%PDF-1.4\n');
    out.add(const [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);
    obj('<< /Type /Catalog /Pages 2 0 R >>');
    obj('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
    obj(
      '<< /Type /Page /Parent 2 0 R '
      '/MediaBox [0 0 ${_n(pageWidthPt)} ${_n(pageHeightPt)}] '
      '/Resources << /XObject << /Im1 5 0 R >> >> /Contents 4 0 R >>',
    );
    streamObj('<< /Length ${content.length} >>', content);
    streamObj(
      '<< /Type /XObject /Subtype /Image /Width ${raster.width} '
      '/Height ${raster.height} /ColorSpace /DeviceGray '
      '/BitsPerComponent 8 /Filter /FlateDecode /Length ${image.length} >>',
      image,
    );
    obj('<< /Producer (DisTrack) >>');

    final xref = out.length;
    final size = offsets.length + 1;
    final table = StringBuffer('xref\n0 $size\n0000000000 65535 f \n');
    for (final o in offsets) {
      table.write('${o.toString().padLeft(10, '0')} 00000 n \n');
    }
    table
      ..write('trailer\n<< /Size $size /Root 1 0 R /Info 6 0 R >>\n')
      ..write('startxref\n$xref\n%%EOF\n');
    ascii(table.toString());
    return out.takeBytes();
  }

  /// Número PDF con 2 decimales y sin ceros de más.
  static String _n(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }
}
