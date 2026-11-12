import 'package:flutter/foundation.dart';

/// Qué ofrece el teléfono para los widgets de la pantalla de inicio
/// (respuesta de "isSupported" del canal `bo.com.dismac/widgets`).
@immutable
class HomeWidgetsSupport {
  const HomeWidgetsSupport({required this.pinSupported});

  /// Sin canal (tests, escritorio) o error del nativo.
  static const HomeWidgetsSupport none = HomeWidgetsSupport(
    pinSupported: false,
  );

  /// ¿El launcher permite agregar un widget desde la app ("Agregar a la
  /// pantalla de inicio")? Android 8+ con launcher compatible; iOS no.
  final bool pinSupported;

  factory HomeWidgetsSupport.fromMap(Map<Object?, Object?>? map) =>
      HomeWidgetsSupport(pinSupported: map?['pinSupported'] == true);
}
