import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/core/push/push_status.dart';

/// Controlador de push falso: devuelve un [PushStatus] fijo en `build()` (sin
/// arrancar el plumbing real de UnifiedPush) y cuenta las llamadas a [register].
/// Permite probar el [PushStatusCard] en cada estado sin tocar la plataforma.
class FakePushController extends PushController {
  FakePushController(this._initial);

  final PushStatus _initial;
  int registerCalls = 0;

  @override
  PushStatus build() => _initial;

  @override
  Future<void> register() async {
    registerCalls++;
    state = state.copyWith(state: PushRegistrationState.registering);
  }
}
