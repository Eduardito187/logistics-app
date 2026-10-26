import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'driver_controllers.dart';

/// Precarga del día del chofer desde el inicio: dispara la tripulación
/// ([myCrewProvider]) y, apenas hay vehículo, la ruta ([driverRouteProvider]),
/// sin esperar al permiso de ubicación ni a que el chofer abra una pantalla.
/// Mientras mira el inicio se resuelve todo, y "Entrega en curso" / "Mi ruta"
/// abren con el dato ya en caché.
///
/// No bloquea ni lanza: es fire-and-forget y cualquier error (sin asignación,
/// sin señal) se ignora acá; la pantalla lo mostrará al abrirse. Llamarla
/// varias veces es barato (los providers ya cargados no se vuelven a pedir).
///
/// Llamarla desde `initState` o un callback (no hace falta esperar nada).
void prefetchDriverDay(WidgetRef ref) {
  unawaited(
    prefetchDriverDayIn(ProviderScope.containerOf(ref.context, listen: false)),
  );
}

/// Igual que [prefetchDriverDay], sobre el [ProviderContainer] (tests o código
/// sin `WidgetRef`). Devuelve el futuro por si alguien quiere esperarlo.
Future<void> prefetchDriverDayIn(ProviderContainer container) async {
  try {
    await container.read(myCrewProvider.future);
  } on Object {
    return; // Sin asignación o sin red: nada que precargar.
  }
  ProviderSubscription<Object?>? sub;
  try {
    // La ruta es autoDispose con caché corta: se la escucha mientras carga y
    // al soltarla queda viva [CacheTtl.short] para la pantalla que la abra.
    sub = container.listen(driverRouteProvider, (_, _) {});
    await container.read(driverRouteProvider.future);
  } on Object {
    // Best-effort: el error se muestra cuando el chofer abra la pantalla.
  } finally {
    sub?.close();
  }
}
