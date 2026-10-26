import 'package:flutter/widgets.dart';

import 'device_memory.dart';

/// Aplica el [MemoryBudget] a la caché global de imágenes.
void applyImageCacheBudget(MemoryBudget budget, {ImageCache? cache}) {
  (cache ?? PaintingBinding.instance.imageCache)
    ..maximumSizeBytes = budget.imageCacheBytes
    ..maximumSize = budget.imageCacheCount;
}

/// Libera memoria cuando el sistema lo pide (Android `onTrimMemory`, iOS
/// `didReceiveMemoryWarning`) y, en equipos de gama baja, al ir a segundo
/// plano. Lo que se suelta se vuelve a cargar solo (de disco o de red) al
/// volver a mostrarse; nada de datos de negocio se pierde.
class MemoryPressureObserver with WidgetsBindingObserver {
  MemoryPressureObserver({required this.budget, ImageCache? cache})
    : _cache = cache;

  final MemoryBudget budget;
  final ImageCache? _cache;

  ImageCache get _imageCache => _cache ?? PaintingBinding.instance.imageCache;

  /// Veces que se liberó memoria (para tests y diagnóstico).
  int trims = 0;

  void attach() => WidgetsBinding.instance.addObserver(this);

  void detach() => WidgetsBinding.instance.removeObserver(this);

  void _trim() {
    trims++;
    _imageCache
      ..clear()
      ..clearLiveImages();
  }

  @override
  void didHaveMemoryPressure() => _trim();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (budget.trimOnBackground && state == AppLifecycleState.paused) {
      _trim();
    }
  }
}
