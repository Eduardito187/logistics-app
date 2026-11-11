import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'home_widget_kind.dart';

/// Preferencias de widgets de UN usuario (por cuenta, no por teléfono): qué
/// widgets apagó del selector y si oculta el nombre del cliente.
@immutable
class HomeWidgetsPrefs {
  const HomeWidgetsPrefs({
    required this.userKey,
    this.disabledKinds = const {},
    this.hideCustomer = false,
  });

  /// Usuario dueño de estas preferencias (ver `HomeWidgetsPrefsStore.userKeyOf`).
  final String userKey;

  /// Widgets que el usuario apagó ("Mostrar en el selector" en OFF).
  final Set<HomeWidgetKind> disabledKinds;

  /// "Ocultar nombre del cliente en widgets" (por defecto OFF).
  final bool hideCustomer;

  HomeWidgetsPrefs copyWith({
    Set<HomeWidgetKind>? disabledKinds,
    bool? hideCustomer,
  }) => HomeWidgetsPrefs(
    userKey: userKey,
    disabledKinds: disabledKinds ?? this.disabledKinds,
    hideCustomer: hideCustomer ?? this.hideCustomer,
  );

  /// JSON guardado en el almacén seguro.
  String encode() => jsonEncode({
    'disabled': [
      for (final kind in HomeWidgetKind.values)
        if (disabledKinds.contains(kind)) kind.backendKey,
    ],
    'hideCustomer': hideCustomer,
  });

  /// Lee [raw] (JSON de [encode]); ausente o corrupto → valores por defecto.
  factory HomeWidgetsPrefs.decode(String userKey, String? raw) {
    if (raw == null || raw.isEmpty) return HomeWidgetsPrefs(userKey: userKey);
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return HomeWidgetsPrefs(userKey: userKey);
      final disabled = map['disabled'];
      return HomeWidgetsPrefs(
        userKey: userKey,
        disabledKinds: {
          if (disabled is List)
            for (final key in disabled)
              if (key is String) ?HomeWidgetKind.fromBackendKey(key),
        },
        hideCustomer: map['hideCustomer'] == true,
      );
    } on FormatException {
      return HomeWidgetsPrefs(userKey: userKey);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetsPrefs &&
      other.userKey == userKey &&
      other.hideCustomer == hideCustomer &&
      setEquals(other.disabledKinds, disabledKinds);

  @override
  int get hashCode => Object.hash(
    userKey,
    hideCustomer,
    Object.hashAllUnordered(disabledKinds),
  );
}
