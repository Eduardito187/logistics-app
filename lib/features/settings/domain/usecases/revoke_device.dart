import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../repositories/settings_repository.dart';

/// Caso de uso (Command, CQRS): revoca la sesión de un dispositivo por su uuid.
/// Delega en el repositorio; propaga `ApiException` ante un error.
class RevokeDevice {
  const RevokeDevice(this._repo);

  final SettingsRepository _repo;

  Future<void> call(String uuid) => _repo.revokeDevice(uuid);
}

final revokeDeviceProvider = Provider<RevokeDevice>(
  (ref) => RevokeDevice(ref.watch(settingsRepositoryProvider)),
);
