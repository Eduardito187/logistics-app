import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/device_list_item.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../repositories/settings_repository.dart';

/// Caso de uso (Query, CQRS): lista los dispositivos/sesiones del usuario.
/// Delega en el repositorio; propaga `ApiException` ante un error.
class ListDevices {
  const ListDevices(this._repo);

  final SettingsRepository _repo;

  Future<List<DeviceListItem>> call() => _repo.listDevices();
}

final listDevicesProvider = Provider<ListDevices>(
  (ref) => ListDevices(ref.watch(settingsRepositoryProvider)),
);
