import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/app_me_response.dart';
import '../../../../core/api/models/device_list_item.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/get_me.dart';
import '../../domain/usecases/list_devices.dart';

/// Controllers de lectura del feature de ajustes. Leen a través de los casos de
/// uso (nunca tocan el cliente de la API). Las escrituras (revocar dispositivo)
/// se ejecutan vía su caso de uso desde las pantallas e invalidan estos
/// proveedores para refrescar.

/// Perfil del usuario, dispositivo actual y habilidades, vía [GetMe].
///
/// Caché larga: el perfil casi no cambia en el turno y antes se pedía
/// `GET /me` cada vez que se abría Ajustes. El botón "Actualizar" lo invalida.
final appMeProvider = FutureProvider.autoDispose<AppMeResponse>((ref) {
  ref.cacheFor(CacheTtl.long);
  // Otra sesión (cerrar y entrar con otro usuario) descarta la caché.
  ref.watch(sessionProvider.select((s) => (s?.token, s?.userName)));
  return ref.watch(getMeProvider).call();
});

/// Dispositivos/sesiones del usuario, vía [ListDevices]. Caché corta; revocar
/// lo invalida.
final devicesProvider = FutureProvider.autoDispose<List<DeviceListItem>>((ref) {
  ref.cacheFor(CacheTtl.short);
  ref.watch(sessionProvider.select((s) => (s?.token, s?.userName)));
  return ref.watch(listDevicesProvider).call();
});
