import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import 'extra_network_input.dart';
import 'ipv4_subnet.dart';

/// Redes extra (además de la del teléfono) donde buscar impresoras, elegidas
/// por el usuario y persistidas en el almacén seguro del dispositivo.
///
/// Arranca vacía y carga lo guardado en segundo plano (como el alto
/// contraste); [current] espera esa carga (lo usa el escáner).
class ExtraNetworksNotifier extends Notifier<List<Ipv4Subnet>> {
  /// Clave en el almacén seguro: lista JSON de `a.b.c.d/n`.
  static const storageKey = 'pref_printer_extra_networks';

  Future<void>? _loading;
  bool _changedByUser = false;

  @override
  List<Ipv4Subnet> build() {
    _loading = _load();
    unawaited(_loading);
    return const [];
  }

  /// Redes guardadas, esperando la carga inicial.
  Future<List<Ipv4Subnet>> current() async {
    await (_loading ?? Future<void>.value());
    return state;
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(tokenStoreProvider).readPref(storageKey);
      if (!ref.mounted || _changedByUser || raw == null) return;
      state = decode(raw);
    } on Object {
      // Almacén no disponible: sin redes extra (no es crítico).
    }
  }

  /// Agrega la red escrita por el usuario. Devuelve el error a mostrar, o
  /// `null` si quedó agregada (una repetida no se duplica).
  Future<String?> add(String input) async {
    final (subnet, error) = ExtraNetworkInput.parse(input);
    if (subnet == null) return error;
    await current();
    if (state.contains(subnet)) return null;
    _changedByUser = true;
    state = List.unmodifiable([...state, subnet]);
    await _persist();
    return null;
  }

  Future<void> remove(Ipv4Subnet subnet) async {
    await current();
    _changedByUser = true;
    state = List.unmodifiable(state.where((s) => s != subnet));
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: storageKey, value: encode(state));
    } on Object {
      // Si no se pudo guardar, igual rige mientras la app siga abierta.
    }
  }

  /// Lista → JSON (`["192.168.2.0/24"]`).
  static String encode(List<Ipv4Subnet> networks) =>
      jsonEncode([for (final n in networks) n.label]);

  /// JSON → lista; ignora entradas corruptas o inválidas.
  static List<Ipv4Subnet> decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <Ipv4Subnet>[];
      for (final item in decoded) {
        if (item is! String) continue;
        final (subnet, _) = ExtraNetworkInput.parse(item);
        if (subnet != null && !out.contains(subnet)) out.add(subnet);
      }
      return List.unmodifiable(out);
    } on FormatException {
      return const [];
    }
  }
}

final extraNetworksProvider =
    NotifierProvider<ExtraNetworksNotifier, List<Ipv4Subnet>>(
      ExtraNetworksNotifier.new,
    );
