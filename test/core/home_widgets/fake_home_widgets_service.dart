import 'package:logistics_app/core/home_widgets/home_widget_kind.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_service.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_support.dart';

/// Servicio de widgets falso: registra cada llamada al canal.
class FakeHomeWidgetsService extends HomeWidgetsService {
  FakeHomeWidgetsService({this.pinSupported = false, this.pinResult = true});

  final bool pinSupported;
  final bool pinResult;

  /// "método" o "método:kind" en orden.
  final List<String> calls = [];

  /// Último payload enviado por kind.
  final Map<HomeWidgetKind, Map<String, Object?>> payloads = {};

  final List<List<HomeWidgetKind>> enabledCalls = [];
  final List<HomeWidgetKind> pinned = [];

  int updatesOf(HomeWidgetKind kind) =>
      calls.where((c) => c == 'update:${kind.backendKey}').length;

  @override
  Future<HomeWidgetsSupport> isSupported() async =>
      HomeWidgetsSupport(pinSupported: pinSupported);

  @override
  Future<void> update(HomeWidgetKind kind, Map<String, Object?> payload) async {
    calls.add('update:${kind.backendKey}');
    payloads[kind] = payload;
  }

  @override
  Future<void> clearAll() async => calls.add('clearAll');

  @override
  Future<void> setEnabledKinds(List<HomeWidgetKind> kinds) async {
    calls.add('setEnabledKinds');
    enabledCalls.add(kinds);
  }

  @override
  Future<bool> requestPin(HomeWidgetKind kind) async {
    calls.add('requestPin:${kind.backendKey}');
    pinned.add(kind);
    return pinResult;
  }
}
