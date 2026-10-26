import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/performance/cache_for.dart';

void main() {
  test(
    'cacheFor: el dato sobrevive al dejar de escucharlo hasta el plazo',
    () async {
      const ttl = Duration(milliseconds: 120);
      var builds = 0;
      final provider = Provider.autoDispose<int>((ref) {
        ref.cacheFor(ttl);
        return ++builds;
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Primera pantalla lo usa y se va.
      container.listen(provider, (_, _) {}).close();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Volver antes del plazo: mismo dato, sin reconstruir (sin request).
      final sub = container.listen(provider, (_, _) {});
      expect(sub.read(), 1);
      expect(builds, 1);
      sub.close();

      // Pasado el plazo sin nadie escuchando se libera.
      await Future<void>.delayed(ttl * 2);
      final again = container.listen(provider, (_, _) {});
      expect(again.read(), 2);
      expect(builds, 2);
      again.close();
    },
  );
}
