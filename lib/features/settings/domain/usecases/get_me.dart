import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/app_me_response.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../repositories/settings_repository.dart';

/// Caso de uso (Query, CQRS): perfil del usuario, dispositivo actual y
/// habilidades. Delega en el repositorio; propaga `ApiException` ante un error.
class GetMe {
  const GetMe(this._repo);

  final SettingsRepository _repo;

  Future<AppMeResponse> call() => _repo.getMe();
}

final getMeProvider = Provider<GetMe>(
  (ref) => GetMe(ref.watch(settingsRepositoryProvider)),
);
