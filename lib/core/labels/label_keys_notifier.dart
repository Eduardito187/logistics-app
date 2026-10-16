import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/dio_client.dart';
import 'label_key_store.dart';

/// Fuente de claves públicas de etiquetas (id → bytes), combinando tres orígenes
/// con ROTACIÓN (se conservan todas las claves conocidas; la anterior sigue
/// siendo válida mientras circulen etiquetas impresas con ella):
///   1. Embebidas en el binario (`--dart-define=LABEL_PUBLIC_KEYS`).
///   2. Caché local segura (último fetch, para verificar offline).
///   3. Backend (`/app/labels/public-keys`), fusionadas al refrescar.
class LabelKeysNotifier extends Notifier<Map<int, List<int>>> {
  @override
  Map<int, List<int>> build() {
    // Arranca de inmediato con las claves embebidas para no bloquear el primer
    // escaneo; en segundo plano fusiona las cacheadas del último fetch.
    final initial = _parseConfig(AppConfig.labelPublicKeys);
    Future.microtask(_loadCache);
    return initial;
  }

  Future<void> _loadCache() async {
    final cached = await ref.read(labelKeyStoreProvider).read();
    _mergeBase64(cached);
  }

  /// Trae las claves del backend y las fusiona con las que ya hay (unión), y las
  /// persiste en caché. Pensado para llamarse al iniciar sesión o desde Ajustes.
  /// Requiere sesión (el endpoint va por la puerta /app/*); sin red se ignora.
  Future<void> refresh() async {
    try {
      final response = await ref
          .read(logisticsApiProvider)
          .labels
          .getLabelPublicKeys();
      final fetched = <int, String>{
        for (final key in response.data.keys) key.id: key.publicKey,
      };
      if (fetched.isEmpty) return;
      final store = ref.read(labelKeyStoreProvider);
      final merged = <int, String>{...await store.read(), ...fetched};
      await store.write(merged);
      _mergeBase64(fetched);
    } on Exception {
      // Sin red o error: se conserva lo embebido/cacheado. El escaneo sigue.
    }
  }

  void _mergeBase64(Map<int, String> base64Keys) {
    final decoded = <int, List<int>>{};
    base64Keys.forEach((id, value) {
      try {
        decoded[id] = base64.decode(value);
      } on FormatException {
        // Clave corrupta en caché: se ignora.
      }
    });
    if (decoded.isEmpty) return;
    state = {...state, ...decoded};
  }

  static Map<int, List<int>> _parseConfig(String raw) {
    final keys = <int, List<int>>{};
    for (final entry
        in raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      final separator = entry.indexOf(':');
      if (separator <= 0) continue;
      final id = int.tryParse(entry.substring(0, separator));
      if (id == null) continue;
      try {
        keys[id] = base64.decode(entry.substring(separator + 1));
      } on FormatException {
        // Entrada mal formada: se ignora.
      }
    }
    return keys;
  }
}

final labelKeysProvider =
    NotifierProvider<LabelKeysNotifier, Map<int, List<int>>>(
      LabelKeysNotifier.new,
    );
