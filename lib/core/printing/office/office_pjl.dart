import 'dart:convert';
import 'dart:typed_data';

import '../printer_credentials.dart';

/// Cabecera/pie PJL del driver Ricoh (verificado capturando su salida real) que
/// autentica el trabajo por el puerto 9100: código de usuario (`USERCODE`),
/// nombre de login e, opcional, "Impresión bloqueada" (`SECUREJOB` +
/// `JOBPASSWORD5`). La usan el envío PDF directo y el PCL. El cuerpo (PDF o
/// PCL) va entre [header] y [footer]; [header] termina en `ENTER LANGUAGE`.
abstract final class OfficePjl {
  /// Universal Exit Language (entra/sale de PJL).
  static const String uel = '\x1B%-12345X';

  /// Cabecera PJL hasta `@PJL ENTER LANGUAGE=<language>` inclusive.
  ///
  /// [language] es el lenguaje del cuerpo que sigue: `PDF` (PDF directo, la vía
  /// que acepta la Ricoh) o `PCL`.
  static Uint8List header({
    required String language,
    required String jobName,
    required String userName,
    PrinterCredentials? credentials,
  }) {
    final job = sanitize(jobName);
    final login = sanitize(credentials?.username ?? userName);
    final userId = login.length > 8 ? login.substring(0, 8) : login;
    final code = (credentials?.hasUserCode ?? false)
        ? sanitize(credentials!.userCode!)
        : null;
    final secure = credentials?.hasSecureToken ?? false;
    final out = BytesBuilder(copy: false);
    void text(String s) => out.add(latin1.encode(s));

    text('$uel@PJL JOB NAME="$job"\r\n');
    // "Impresión bloqueada": el trabajo se retiene y se libera en el panel.
    if (secure) text('@PJL SECUREJOB\r\n');
    text('@PJL SET USERNAME="$login"\r\n');
    text('@PJL SET JOBNAME="$job"\r\n');
    // Extensiones Ricoh (otras marcas las ignoran).
    text('@PJL SET DOCPRINTMENUUSER=HOSTLOGINNAME\r\n');
    text('@PJL SET USERID="$userId"\r\n');
    text('@PJL SET HOSTLOGINNAME="$login"\r\n');
    if (code != null) {
      text('@PJL SET USERCODE="$code"\r\n');
      text('@PJL SET BILLINGCODE="$code"\r\n');
    }
    if (secure) {
      text(
        '@PJL SET JOBPASSWORD5="${sanitize(credentials!.secureToken!)}"\r\n',
      );
    }
    text('@PJL ENTER LANGUAGE=$language\r\n');
    return out.takeBytes();
  }

  /// Pie PJL: fin del lenguaje y del trabajo.
  static Uint8List footer(String jobName) =>
      latin1.encode('$uel@PJL EOJ NAME="${sanitize(jobName)}"\r\n$uel');

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
