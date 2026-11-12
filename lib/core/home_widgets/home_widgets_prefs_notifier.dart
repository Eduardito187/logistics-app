import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import 'home_widget_kind.dart';
import 'home_widgets_prefs.dart';
import 'home_widgets_prefs_store.dart';

/// Preferencias de widgets del usuario logueado. `null` sin sesión o mientras
/// se leen del almacén (una lectura por login).
class HomeWidgetsPrefsNotifier extends Notifier<HomeWidgetsPrefs?> {
  @override
  HomeWidgetsPrefs? build() {
    final userName = ref.watch(sessionProvider.select((s) => s?.userName));
    if (userName == null) return null;
    unawaited(_load(HomeWidgetsPrefsStore.userKeyOf(userName)));
    return null;
  }

  Future<void> _load(String userKey) async {
    final prefs = await ref.read(homeWidgetsPrefsStoreProvider).read(userKey);
    if (!ref.mounted || state != null) return;
    // Pudo cambiar el usuario mientras se leía.
    final current = ref.read(sessionProvider)?.userName;
    if (current == null ||
        HomeWidgetsPrefsStore.userKeyOf(current) != userKey) {
      return;
    }
    state = prefs;
  }

  /// "Mostrar en el selector" del widget [kind].
  Future<void> setKindEnabled(HomeWidgetKind kind, bool enabled) async {
    final current = state;
    if (current == null) return;
    final disabled = {...current.disabledKinds};
    if (enabled) {
      disabled.remove(kind);
    } else {
      disabled.add(kind);
    }
    await _save(current.copyWith(disabledKinds: disabled));
  }

  /// "Ocultar nombre del cliente en widgets".
  Future<void> setHideCustomer(bool hide) async {
    final current = state;
    if (current == null) return;
    await _save(current.copyWith(hideCustomer: hide));
  }

  Future<void> _save(HomeWidgetsPrefs next) async {
    state = next;
    await ref.read(homeWidgetsPrefsStoreProvider).write(next);
  }
}

final homeWidgetsPrefsProvider =
    NotifierProvider<HomeWidgetsPrefsNotifier, HomeWidgetsPrefs?>(
      HomeWidgetsPrefsNotifier.new,
    );
