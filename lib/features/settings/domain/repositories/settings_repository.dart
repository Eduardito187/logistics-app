import '../../../../core/api/models/app_me_response.dart';
import '../../../../core/api/models/device_list_item.dart';

/// Contrato del feature de ajustes (perfil, dispositivos y configuración). La
/// capa `data` lo implementa; la capa `presentation` sólo lo conoce a través de
/// los casos de uso. Lanza `ApiException` ante un error.
abstract interface class SettingsRepository {
  /// Perfil del usuario, dispositivo actual y habilidades.
  Future<AppMeResponse> getMe();

  /// Dispositivos/sesiones del usuario.
  Future<List<DeviceListItem>> listDevices();

  /// Revoca la sesión de un dispositivo por su uuid.
  Future<void> revokeDevice(String uuid);
}
