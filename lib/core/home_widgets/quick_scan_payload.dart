import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';

/// "Escanear" (todos los roles con escaneo): abre la tarea de escaneo
/// principal del rol. Sin sesión queda como único widget, invitando a iniciar
/// sesión ([HomeWidgetState.signedOut]).
class QuickScanPayload extends HomeWidgetPayload {
  const QuickScanPayload({required this.state, required this.route});

  /// Texto del botón del widget.
  static const String scanLabel = 'Escanear';

  @override
  HomeWidgetKind get kind => HomeWidgetKind.quickScan;

  @override
  final HomeWidgetState state;

  @override
  final String route;

  @override
  Map<String, Object?> get fields => const {'label': scanLabel};
}
