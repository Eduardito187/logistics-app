import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/office/label_raster.dart';
import 'package:logistics_app/core/printing/office/page_layout.dart';
import 'package:logistics_app/core/printing/office/pcl_job_writer.dart';
import 'package:logistics_app/core/printing/office/pdf_direct_job_writer.dart';
import 'package:logistics_app/core/printing/office/pdf_image_writer.dart';
import 'package:logistics_app/core/printing/office/pwg_raster_writer.dart';
import 'package:logistics_app/core/printing/printer_credentials.dart';

// Documentos para impresoras de oficina escritos a mano (sin paquetes): PDF
// con imagen Flate, PWG raster y PCL 5 + PJL con usuario/código Ricoh.

/// Etiqueta de prueba: 4" × 2" a 100 dpi, mitad izquierda negra.
LabelRaster _label({int width = 400, int height = 200, double dpi = 100}) {
  final pixels = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      pixels[y * width + x] = x < width ~/ 2 ? 0 : 255;
    }
  }
  return LabelRaster(width: width, height: height, dpi: dpi, pixels: pixels);
}

/// Descomprime un PWG raster de una página a filas de gris.
List<Uint8List> _decodePwg(Uint8List bytes, int width, int height) {
  var pos = 4 + PwgRasterWriter.headerSize;
  final rows = <Uint8List>[];
  while (rows.length < height) {
    final repeat = bytes[pos++] + 1;
    final row = Uint8List(width);
    var x = 0;
    while (x < width) {
      final n = bytes[pos++];
      if (n < 128) {
        row.fillRange(x, x + n + 1, bytes[pos++]);
        x += n + 1;
      } else {
        final count = 257 - n;
        row.setRange(x, x + count, bytes.sublist(pos, pos + count));
        pos += count;
        x += count;
      }
    }
    for (var i = 0; i < repeat; i++) {
      rows.add(row);
    }
  }
  expect(pos, bytes.length, reason: 'sin bytes de más');
  return rows;
}

void main() {
  group('LabelRaster', () {
    test('RGBA → gris componiendo la transparencia sobre blanco', () {
      final raster = LabelRaster.fromRgba(
        Uint8List.fromList([
          0, 0, 0, 255, // negro opaco
          0, 0, 0, 0, // transparente → blanco
          255, 255, 255, 255, // blanco
        ]),
        width: 3,
        height: 1,
        dpi: 203,
      );
      expect(raster.pixels, [0, 255, 255]);
      expect(raster.widthPoints, closeTo(3 / 203 * 72, 1e-9));
    });
  });

  group('PageLayout', () {
    test('respeta el tamaño físico y centra en A4', () {
      final layout = PageLayout(raster: _label(), dpi: 300);
      expect(layout.pageWidthPx, 2480);
      expect(layout.pageHeightPx, 3508);
      expect(layout.drawWidth, 1200); // 4" a 300 dpi
      expect(layout.drawHeight, 600);
      expect(layout.left, (2480 - 1200) ~/ 2);
      expect(layout.top, (3508 - 600) ~/ 2);
      final row = layout.grayRow(layout.top + 10);
      expect(row[layout.left], 0);
      expect(row[layout.left + 1199], 255);
      expect(row[0], 255);
      expect(layout.isBlankRow(0), isTrue);
    });

    test('achica lo que no entra en la hoja', () {
      final layout = PageLayout(
        raster: _label(width: 1000, height: 100),
        dpi: 100,
      );
      expect(layout.drawWidth, lessThanOrEqualTo(layout.pageWidthPx - 100));
    });
  });

  group('PdfImageWriter', () {
    final pdf = PdfImageWriter.build(_label());
    final text = latin1.decode(pdf);

    test('cabecera %PDF- y fin %%EOF', () {
      expect(text, startsWith('%PDF-1.4\n'));
      expect(text.trimRight(), endsWith('%%EOF'));
    });

    test('xref: cada offset apunta a su "N 0 obj"', () {
      final startxref = int.parse(
        RegExp(r'startxref\n(\d+)\n%%EOF').firstMatch(text)!.group(1)!,
      );
      expect(text.substring(startxref, startxref + 4), 'xref');
      final entries = RegExp(r'(\d{10}) 00000 n \n').allMatches(text).toList();
      expect(entries, hasLength(6));
      for (var i = 0; i < entries.length; i++) {
        final offset = int.parse(entries[i].group(1)!);
        expect(text.substring(offset), startsWith('${i + 1} 0 obj\n'));
      }
      expect(text, contains('/Size 7 /Root 1 0 R'));
    });

    test('la imagen es /DeviceGray Flate y se infla a los píxeles', () {
      final dict = RegExp(
        r'/Subtype /Image /Width 400 /Height 200 /ColorSpace /DeviceGray '
        r'/BitsPerComponent 8 /Filter /FlateDecode /Length (\d+) >>\nstream\n',
      ).firstMatch(text)!;
      final length = int.parse(dict.group(1)!);
      final data = pdf.sublist(dict.end, dict.end + length);
      expect(ZLibCodec().decode(data), _label().pixels);
    });

    test('la etiqueta va centrada a su tamaño físico (4" = 288 pt)', () {
      // A4 595.28 × 841.89; 4" × 2" = 288 × 144 pt.
      expect(
        text,
        matches(RegExp(r'q 288 0 0 144 153\.64 348\.9\d cm /Im1 Do Q')),
      );
    });
  });

  group('PwgRasterWriter', () {
    test('sync RaS2 + cabecera de 1796 bytes con los campos clave', () {
      final bytes = PwgRasterWriter.build(_label(), dpi: 150);
      expect(ascii.decode(bytes.sublist(0, 4)), 'RaS2');
      final header = ByteData.sublistView(bytes, 4, 4 + 1796);
      expect(
        ascii.decode(bytes.sublist(4, 13)),
        'PwgRaster',
      );
      expect(header.getUint32(276), 150); // HWResolution
      expect(header.getUint32(372), 1240); // Width (A4 a 150 dpi)
      expect(header.getUint32(376), 1754); // Height
      expect(header.getUint32(384), 8); // BitsPerColor
      expect(header.getUint32(388), 8); // BitsPerPixel
      expect(header.getUint32(392), 1240); // BytesPerLine
      expect(header.getUint32(400), PwgRasterWriter.colorSpaceSGray);
      expect(header.getUint32(420), 1); // NumColors
      expect(
        ascii.decode(bytes.sublist(4 + 1732, 4 + 1748)),
        'iso_a4_210x297mm',
      );
    });

    test('las filas comprimidas reconstruyen la hoja', () {
      final bytes = PwgRasterWriter.build(_label(), dpi: 150);
      final rows = _decodePwg(bytes, 1240, 1754);
      final layout = PageLayout(raster: _label(), dpi: 150);
      expect(rows.first.every((v) => v == 255), isTrue);
      final middle = rows[layout.top + 5];
      expect(middle[layout.left], 0);
      expect(middle[layout.left + layout.drawWidth - 1], 255);
      expect(middle, layout.grayRow(layout.top + 5));
    });

    test('encodeLine: repeticiones y literales (PackBits PWG)', () {
      final line = Uint8List.fromList([5, 5, 5, 1, 2, 3, 9]);
      expect(PwgRasterWriter.encodeLine(line, 1), [
        2, 5, // 3 × 5
        253, 1, 2, 3, 9, // 4 literales (257 − 4)
      ]);
      // El último literal suelto es "repetir 1 vez".
      expect(PwgRasterWriter.encodeLine(Uint8List.fromList([7]), 1), [0, 7]);
    });
  });

  group('PclJobWriter', () {
    test('PJL con usuario, job, USERID y USERCODE de Ricoh', () {
      final job = PclJobWriter.build(
        _label(),
        jobName: 'Etiqueta "1234"',
        userName: 'sesion',
        credentials: const PrinterCredentials(
          username: 'jperez',
          userCode: '4321',
        ),
      );
      final text = latin1.decode(job);
      expect(text, startsWith('\x1B%-12345X@PJL JOB NAME="Etiqueta _1234_"\r\n'));
      expect(text, contains('@PJL SET USERNAME="jperez"\r\n'));
      expect(text, contains('@PJL SET JOBNAME="Etiqueta _1234_"\r\n'));
      expect(text, contains('@PJL SET DOCPRINTMENUUSER=HOSTLOGINNAME\r\n'));
      expect(text, contains('@PJL SET USERID="jperez"\r\n'));
      expect(text, contains('@PJL SET HOSTLOGINNAME="jperez"\r\n'));
      expect(text, contains('@PJL SET USERCODE="4321"\r\n'));
      expect(text, contains('@PJL SET BILLINGCODE="4321"\r\n'));
      expect(text, contains('@PJL ENTER LANGUAGE=PCL\r\n'));
      // Sin token de bloqueo no va SECUREJOB (imprime directo).
      expect(text, isNot(contains('SECUREJOB')));
      expect(text, isNot(contains('JOBPASSWORD5')));
      expect(text, contains('\x1B*t300R'));
      expect(text, contains('\x1B*r1A'));
      expect(text, contains('\x1B*rB'));
      expect(text, endsWith('@PJL EOJ NAME="Etiqueta _1234_"\r\n\x1B%-12345X'));
      // 2" de alto a 300 dpi = 600 filas de raster.
      expect(RegExp('\x1B\\*b\\d+W').allMatches(text), hasLength(600));
    });

    test('USERID se trunca a 8 (como el driver Ricoh), HOSTLOGINNAME completo', () {
      final text = latin1.decode(
        PclJobWriter.build(
          _label(),
          jobName: 'J',
          userName: 'sesion',
          credentials: const PrinterCredentials(username: 'ehhuallata'),
        ),
      );
      expect(text, contains('@PJL SET USERID="ehhualla"\r\n'));
      expect(text, contains('@PJL SET HOSTLOGINNAME="ehhuallata"\r\n'));
    });

    test('con token de bloqueo: SECUREJOB + JOBPASSWORD5 (impresión retenida)',
        () {
      // Token de EJEMPLO (no una credencial real).
      const fakeToken = 'TOKEN_DE_EJEMPLO_NO_REAL';
      final text = latin1.decode(
        PclJobWriter.build(
          _label(),
          jobName: 'J',
          userName: 'ehhuallata',
          credentials: const PrinterCredentials(
            username: 'ehhuallata',
            userCode: '2468',
            secureToken: fakeToken,
          ),
        ),
      );
      // SECUREJOB va ANTES del resto de la cabecera (como el driver real).
      expect(
        text.indexOf('@PJL SECUREJOB'),
        lessThan(text.indexOf('@PJL SET USERID')),
      );
      expect(text, contains('@PJL SET JOBPASSWORD5="$fakeToken"\r\n'));
      expect(text, contains('@PJL SET USERCODE="2468"\r\n'));
    });

    test('sin código de usuario no manda USERCODE; usa el de la sesión', () {
      final text = latin1.decode(
        PclJobWriter.build(_label(), jobName: 'J', userName: 'ana'),
      );
      expect(text, contains('@PJL SET USERID="ana"'));
      expect(text, isNot(contains('USERCODE')));
    });
  });

  group('PdfDirectJobWriter (la vía del 9100: Ricoh imprime PDF, no PCL)', () {
    test('cabecera PJL + ENTER LANGUAGE=PDF + cuerpo PDF + EOJ', () {
      final job = PdfDirectJobWriter.build(
        _label(),
        jobName: 'Etiqueta 9',
        userName: 'sesion',
        credentials: const PrinterCredentials(
          username: 'ehhuallata',
          userCode: '2468',
        ),
      );
      final text = latin1.decode(job);
      expect(text, startsWith('\x1B%-12345X@PJL JOB NAME="Etiqueta 9"\r\n'));
      expect(text, contains('@PJL SET USERCODE="2468"\r\n'));
      expect(text, contains('@PJL SET USERID="ehhualla"\r\n'));
      expect(text, contains('@PJL ENTER LANGUAGE=PDF\r\n'));
      // El cuerpo es un PDF válido (arranca en %PDF- y termina en %%EOF).
      final pdfStart = text.indexOf('%PDF-');
      expect(pdfStart, greaterThan(0));
      expect(pdfStart, greaterThan(text.indexOf('ENTER LANGUAGE=PDF')));
      expect(text, contains('%%EOF'));
      expect(text, endsWith('@PJL EOJ NAME="Etiqueta 9"\r\n\x1B%-12345X'));
      // No lleva PCL.
      expect(text, isNot(contains('ENTER LANGUAGE=PCL')));
    });

    test('fila: el negro va en 1 (MSB primero)', () {
      final raster = LabelRaster(
        width: 8,
        height: 1,
        dpi: 300,
        pixels: Uint8List.fromList([0, 255, 0, 255, 255, 255, 255, 255]),
      );
      final pcl = PclJobWriter.pclRaster(raster);
      final marker = latin1.encode('\x1B*b1W');
      final at = _indexOf(pcl, marker);
      expect(at, greaterThan(0));
      expect(pcl[at + marker.length], 0xA0);
    });

    test('sanitize quita comillas, controles y no-ASCII', () {
      expect(PclJobWriter.sanitize(' Peña "x"\n'), 'Pe_a _x_');
    });
  });
}

int _indexOf(List<int> data, List<int> pattern) {
  outer:
  for (var i = 0; i <= data.length - pattern.length; i++) {
    for (var j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) continue outer;
    }
    return i;
  }
  return -1;
}
