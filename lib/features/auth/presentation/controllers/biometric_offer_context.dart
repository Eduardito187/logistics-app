import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';

/// Busca dónde mostrar la oferta post-login: el contexto del navigator raíz
/// una vez que el router ya dejó el login (si el diálogo se abriera sobre la
/// ruta del login, el redirect al inicio lo descartaría junto con ella).
/// `null` si no se llegó al inicio a tiempo (no se ofrece).
typedef BiometricOfferContextFinder = Future<BuildContext?> Function();

/// Cuadros máximos a esperar a que el router salga del login (~1 s a 60 Hz).
const _maxFramesToWait = 60;

/// Seam para tests: se override con una función que devuelve el contexto del
/// test.
final biometricOfferContextProvider = Provider<BiometricOfferContextFinder>((
  ref,
) {
  return () async {
    final router = ref.read(routerProvider);
    for (var frame = 0; frame < _maxFramesToWait; frame++) {
      await WidgetsBinding.instance.endOfFrame;
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (!path.startsWith(AppRoutes.login)) {
        // Un cuadro más: la pantalla de inicio ya quedó montada.
        await WidgetsBinding.instance.endOfFrame;
        return router.routerDelegate.navigatorKey.currentContext;
      }
    }
    return null;
  };
});
