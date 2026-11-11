import 'dart:convert';
import 'dart:typed_data';

import '../printer_credentials.dart';
import 'label_raster.dart';
import 'office_pjl.dart';
import 'page_layout.dart';

/// Trabajo PCL 5 (raster monocromo 300 dpi en A4) envuelto en PJL, para
/// impresoras de oficina SIN IPP que solo reciben por el puerto 9100.
///
/// Reproduce la cabecera PJL del driver Ricoh (verificada capturando su salida
/// real, nov 2026) para impresoras con autenticación de usuario:
/// - **Código de usuario** (`USERCODE`/`BILLINGCODE`, texto claro): la Ricoh
///   autentica el trabajo y lo imprime. El operario solo tipea su código.
/// - **Impresión bloqueada** (`SECUREJOB` + `JOBPASSWORD5`): si hay un
///   [PrinterCredentials.secureToken], el trabajo queda RETENIDO y se libera
///   con el código en el panel, igual que desde la PC. El token es el valor
///   base64 opaco que emite el driver (no se descifra; es fijo por usuario).
/// La autenticación Windows/LDAP con contraseña NO es replicable por 9100 (el
/// driver la cifra con un algoritmo propietario): para eso, IPP con Basic.
abstract final class PclJobWriter {
  static const int _esc = 0x1B;

  /// Universal Exit Language (salta a PJL).
  static const String uel = '\x1B%-12345X';

  static Uint8List build(
    LabelRaster raster, {
    required String jobName,
    required String userName,
    PrinterCredentials? credentials,
    int dpi = 300,
  }) {
    final out = BytesBuilder(copy: false);
    out.add(
      OfficePjl.header(
        language: 'PCL',
        jobName: jobName,
        userName: userName,
        credentials: credentials,
      ),
    );
    out.add(pclRaster(raster, dpi: dpi));
    out.add(OfficePjl.footer(jobName));
    return out.takeBytes();
  }

  /// Solo la parte PCL: reset, A4, resolución, raster y salto de página.
  static Uint8List pclRaster(LabelRaster raster, {int dpi = 300}) {
    final layout = PageLayout(raster: raster, dpi: dpi);
    final out = BytesBuilder(copy: false);
    void esc(String s) => out
      ..addByte(_esc)
      ..add(latin1.encode(s));

    esc('E'); // reset
    esc('&l26A'); // A4
    esc('&l0O'); // vertical
    esc('*t${dpi}R'); // resolución del raster
    esc('*p${layout.left}x${layout.top}Y'); // posición (en puntos de 300 dpi)
    esc('*r${layout.drawWidth}S'); // ancho del raster
    esc('*r1A'); // empezar raster en la posición actual
    esc('*b0M'); // sin compresión

    final gray = Uint8List(layout.pageWidthPx);
    final bytesPerRow = (layout.drawWidth + 7) ~/ 8;
    final row = Uint8List(bytesPerRow);
    for (var y = layout.top; y < layout.top + layout.drawHeight; y++) {
      layout.grayRow(y, gray);
      row.fillRange(0, bytesPerRow, 0);
      var used = 0;
      for (var x = 0; x < layout.drawWidth; x++) {
        // Umbral: gris oscuro = punto negro (bit en 1).
        if (gray[layout.left + x] < 128) {
          row[x >> 3] |= 0x80 >> (x & 7);
          used = (x >> 3) + 1;
        }
      }
      esc('*b${used}W');
      if (used > 0) out.add(Uint8List.sublistView(row, 0, used));
    }
    esc('*rB'); // fin del raster
    out.addByte(0x0C); // salto de página
    esc('E');
    return out.takeBytes();
  }

  /// Valor seguro para un string PJL: sin comillas, controles ni no-ASCII.
  static String sanitize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      if (rune < 0x20 || rune > 0x7E || rune == 0x22) {
        buffer.write('_');
      } else {
        buffer.writeCharCode(rune);
      }
    }
    final s = buffer.toString();
    return s.length > 80 ? s.substring(0, 80) : s;
  }
}
