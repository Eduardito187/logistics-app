import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Memoria del teléfono, leída una vez al arrancar desde el código nativo
/// (Android `ActivityManager`, iOS `ProcessInfo`). Sirve para ajustar cachés y
/// precargas al equipo: la app tiene que andar en teléfonos de 1 GB de RAM.
class DeviceMemory {
  const DeviceMemory({this.totalMb, this.memoryClassMb, this.lowRam = false});

  /// Equipo desconocido (tests, web, canal nativo caído): se asume gama media.
  static const unknown = DeviceMemory();

  /// RAM total del equipo en MB (`null` si no se pudo leer).
  final int? totalMb;

  /// Tope de heap Java por app que da el SO (`ActivityManager.memoryClass`).
  /// Es el indicador más limpio de gama en Android: ~16-24 MB en equipos de
  /// 512 MB, ~32-48 MB en 1 GB. `null` fuera de Android o si no se pudo leer.
  final int? memoryClassMb;

  /// El sistema marca el equipo como de poca RAM (Android Go / ≤ 1,5 GB).
  final bool lowRam;

  /// Gama baja EXTREMA (Android Go real, ~512 MB): el SO deja ~120-180 MB a la
  /// app en primer plano, así que hay que ahorrar al máximo. Se detecta por RAM
  /// total (≤ 768 MB) o por un heap Java muy chico (`memoryClass ≤ 24 MB`), que
  /// en la práctica solo lo tienen los equipos de 512 MB.
  bool get isVeryLowEnd =>
      (totalMb != null && totalMb! <= 768) ||
      (memoryClassMb != null && memoryClassMb! <= 24);

  /// Gama baja: hay que ahorrar memoria en todo (≤ 1,5 GB o marcado por el SO).
  bool get isLowEnd => lowRam || (totalMb != null && totalMb! <= 1536);

  /// Gama media: hasta 3 GB.
  bool get isMidRange => !isLowEnd && totalMb != null && totalMb! <= 3072;

  static const _channel = MethodChannel('bo.com.dismac/device_memory');

  /// Lee la memoria del equipo. Nunca falla: ante cualquier error, [unknown].
  static Future<DeviceMemory> load({MethodChannel channel = _channel}) async {
    try {
      final info = await channel.invokeMapMethod<String, Object?>('info');
      if (info == null) return unknown;
      final total = info['totalMb'];
      final memClass = info['memoryClassMb'];
      return DeviceMemory(
        totalMb: total is int && total > 0 ? total : null,
        memoryClassMb: memClass is int && memClass > 0 ? memClass : null,
        lowRam: info['lowRam'] == true,
      );
    } on Object {
      return unknown;
    }
  }
}

/// Presupuesto de memoria por gama de equipo.
class MemoryBudget {
  const MemoryBudget({
    required this.imageCacheBytes,
    required this.imageCacheCount,
    required this.trimOnBackground,
  });

  factory MemoryBudget.forDevice(DeviceMemory device) {
    if (device.isVeryLowEnd) {
      // 512 MB (Android Go real): el SO deja ~120-180 MB a la app; 24 MB de
      // bitmaps decodificados serían la mitad del heap compitiendo con mapa y
      // cámara → OOM/kill (que mata el GPS en ruta). Caché bien chica: ~24
      // tiles o un par de fotos, y se suelta siempre al ir a segundo plano.
      return const MemoryBudget(
        imageCacheBytes: 10 << 20,
        imageCacheCount: 24,
        trimOnBackground: true,
      );
    }
    if (device.isLowEnd) {
      // 1 GB: el mapa, la cámara y el sistema ya ocupan casi todo.
      return const MemoryBudget(
        imageCacheBytes: 24 << 20,
        imageCacheCount: 50,
        trimOnBackground: true,
      );
    }
    if (device.isMidRange || device.totalMb == null) {
      return const MemoryBudget(
        imageCacheBytes: 40 << 20,
        imageCacheCount: 80,
        trimOnBackground: false,
      );
    }
    return const MemoryBudget(
      imageCacheBytes: 64 << 20,
      imageCacheCount: 120,
      trimOnBackground: false,
    );
  }

  /// Tope de la caché de imágenes decodificadas (tiles, fotos, productos).
  final int imageCacheBytes;
  final int imageCacheCount;

  /// Al pasar a segundo plano se vacían las imágenes decodificadas: menos RAM
  /// retenida = menos chance de que el sistema mate la app (y el GPS).
  final bool trimOnBackground;
}

/// Memoria del equipo. `main.dart` lo sobreescribe con el valor leído al
/// arrancar; en tests queda como equipo desconocido.
final deviceMemoryProvider = Provider<DeviceMemory>(
  (ref) => DeviceMemory.unknown,
);
