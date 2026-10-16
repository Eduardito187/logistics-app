import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/app_me_response.dart';
import '../../../../core/api/models/device_list_item.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/list_devices.dart';

/// Controllers de lectura del feature de ajustes. Leen a través de los casos de
/// uso (nunca tocan el cliente de la API). Las escrituras (revocar dispositivo)
/// se ejecutan vía su caso de uso desde las pantallas e invalidan estos
/// proveedores para refrescar.

/// Perfil del usuario, dispositivo actual y habilidades, vía [GetMe].
final appMeProvider = FutureProvider.autoDispose<AppMeResponse>((ref) {
  return ref.watch(getMeProvider).call();
});

/// Dispositivos/sesiones del usuario, vía [ListDevices].
final devicesProvider = FutureProvider.autoDispose<List<DeviceListItem>>((ref) {
  return ref.watch(listDevicesProvider).call();
});
