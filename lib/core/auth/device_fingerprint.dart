import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Huella del dispositivo que viaja en el login (`device.fingerprint`): una por
/// **instalación + usuario**, no una por teléfono.
///
/// Por qué: el backend identifica la fila `devices` por esta huella y, si la
/// huella fuera solo del teléfono, al entrar OTRO usuario en el mismo teléfono
/// la misma fila cambia de dueño. La guarda del backend cachea ~30 s el dueño
/// del dispositivo, y durante esa ventana rechazaba la sesión recién abierta
/// con "Este dispositivo fue dado de baja" (bug crítico, nov 2026). Con una
/// fila por usuario no hay re-asignación y el caché nunca queda desfasado.
///
/// Sin datos personales: el email entra solo como hash (SHA-256, 16 hex).
/// Estable: el mismo usuario en la misma instalación da siempre la misma huella
/// (su fila, su push token y su "1 sesión por plataforma" se conservan).
Future<String> userDeviceFingerprint({
  required String installId,
  required String email,
}) async {
  final normalized = email.trim().toLowerCase();
  final digest = await Sha256().hash(utf8.encode('$installId|$normalized'));
  final hex = digest.bytes
      .take(8)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '$installId-u$hex';
}
