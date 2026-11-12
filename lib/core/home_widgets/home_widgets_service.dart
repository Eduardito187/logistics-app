import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_widget_kind.dart';
import 'home_widgets_support.dart';

/// Puente con el canal nativo `bo.com.dismac/widgets`:
/// - Android: AppWidgetProviders (uno por kind); "setEnabledKinds" los
///   habilita/deshabilita en el selector de widgets.
/// - iOS: WidgetKit (App Group); "setEnabledKinds" es no-op.
///
/// Métodos: "isSupported" → `{"pinSupported": bool}`, "update"
/// `{"kind", "payload"}`, "clearAll", "setEnabledKinds" `{"kinds": [..]}`,
/// "requestPin" `{"kind"}` → bool.
///
/// Nunca falla: sin canal (tests, escritorio → `MissingPluginException`) o ante
/// un error del nativo, la llamada es un no-op. Los widgets son un extra.
class HomeWidgetsService {
  const HomeWidgetsService({MethodChannel channel = defaultChannel})
    : _channel = channel;

  static const MethodChannel defaultChannel = MethodChannel(
    'bo.com.dismac/widgets',
  );

  final MethodChannel _channel;

  Future<HomeWidgetsSupport> isSupported() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'isSupported',
      );
      return HomeWidgetsSupport.fromMap(map);
    } on Object {
      return HomeWidgetsSupport.none;
    }
  }

  /// Publica el contenido de un widget.
  Future<void> update(HomeWidgetKind kind, Map<String, Object?> payload) =>
      _invoke('update', {'kind': kind.backendKey, 'payload': payload});

  /// Borra los datos de todos los widgets (cierre de sesión).
  Future<void> clearAll() => _invoke('clearAll');

  /// Widgets que el selector del sistema ofrece (Android).
  Future<void> setEnabledKinds(List<HomeWidgetKind> kinds) =>
      _invoke('setEnabledKinds', {
        'kinds': [for (final kind in kinds) kind.backendKey],
      });

  /// Pide al launcher agregar el widget [kind] a la pantalla de inicio.
  /// `true` si el sistema aceptó el pedido (muestra su propia confirmación).
  Future<bool> requestPin(HomeWidgetKind kind) async =>
      await _invoke('requestPin', {'kind': kind.backendKey}) == true;

  Future<Object?> _invoke(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on MissingPluginException {
      return null;
    } on Object {
      // Error del nativo (launcher sin soporte, App Group ausente, etc.).
      return null;
    }
  }
}

/// Servicio de widgets. Seam para tests (`overrideWithValue` con un falso).
final homeWidgetsServiceProvider = Provider<HomeWidgetsService>(
  (ref) => const HomeWidgetsService(),
);

/// Soporte del teléfono (botón "Agregar a la pantalla de inicio" de Ajustes).
final homeWidgetsSupportProvider =
    FutureProvider.autoDispose<HomeWidgetsSupport>(
      (ref) => ref.watch(homeWidgetsServiceProvider).isSupported(),
    );
