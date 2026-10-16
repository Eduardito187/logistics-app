import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/app_me_response.dart';
import '../../../../core/api/models/device_list_item.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';

/// Implementación del contrato de ajustes. Delega cada operación en el data
/// source remoto; no agrega comportamiento propio.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<AppMeResponse> getMe() => _remote.getMe();

  @override
  Future<List<DeviceListItem>> listDevices() => _remote.listDevices();

  @override
  Future<void> revokeDevice(String uuid) => _remote.revokeDevice(uuid);
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(settingsRemoteDataSourceProvider)),
);
