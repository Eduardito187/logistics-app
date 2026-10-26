import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/features/home/presentation/home_prefetch.dart';

/// `HomePrefetcher` que no hace nada. Para tests que montan el Inicio pero NO
/// prueban la precarga: sin esto, el prefetch real toca la red y deja timers de
/// Dio colgados al terminar el test (`!timersPending`).
class NoHomePrefetcher implements HomePrefetcher {
  const NoHomePrefetcher();

  @override
  void call(WidgetRef ref, UserRole role) {}
}

/// Override listo para la lista de overrides de un `ProviderContainer`/`Scope`.
final noHomePrefetchOverride = homePrefetcherProvider.overrideWithValue(
  const NoHomePrefetcher(),
);
