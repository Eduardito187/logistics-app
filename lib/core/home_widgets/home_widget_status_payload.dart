import 'home_widget_kind.dart';
import 'home_widget_payload.dart';
import 'home_widget_state.dart';

/// Payload SIN datos: solo el estado y la ruta. Se usa para los widgets que no
/// son del rol ([HomeWidgetState.notAllowed]) y como "todavía sin datos"
/// ([HomeWidgetState.empty]) al iniciar sesión, antes de que el inicio cargue
/// lo que el widget refleja.
class HomeWidgetStatusPayload extends HomeWidgetPayload {
  const HomeWidgetStatusPayload({
    required this.kind,
    required this.state,
    required this.route,
  });

  @override
  final HomeWidgetKind kind;

  @override
  final HomeWidgetState state;

  @override
  final String route;

  @override
  Map<String, Object?> get fields => const {};
}
