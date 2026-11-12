import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'label_key_store.dart';

/// Modo ABIERTO de etiquetas (señal autoritativa `open` de
/// `GET /app/labels/public-keys`).
///
/// En modo abierto una etiqueta NO se verifica por firma Ed25519 (ni las nuevas
/// `k:0` ni las viejas `k:1` ya impresas): su autenticidad la decide el
/// registro/pertenencia (que el `id` pertenezca al envío/ruta). Así una etiqueta
/// impresa NUNCA se descarta por un tema de claves (decisión del dueño).
///
/// El valor se persiste (último fetch) para que el escaneo offline lo recuerde
/// entre sesiones. Lo setea [LabelKeysNotifier.refresh] al traer el bundle.
class LabelsOpenModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Arranca en FIRMADO (false) y, en segundo plano, carga el último valor
    // conocido de la caché (no bloquea el primer escaneo).
    Future.microtask(() async {
      try {
        final cached = await ref.read(labelKeyStoreProvider).readOpen();
        if (cached != state) state = cached;
      } on Object {
        // Sin almacén disponible (p. ej. en tests sin plugin): queda en firmado.
      }
    });
    return false;
  }

  /// Fija el modo abierto traído del backend y lo persiste.
  Future<void> set(bool open) async {
    state = open;
    await ref.read(labelKeyStoreProvider).writeOpen(open);
  }
}

final labelsOpenModeProvider = NotifierProvider<LabelsOpenModeNotifier, bool>(
  LabelsOpenModeNotifier.new,
);
