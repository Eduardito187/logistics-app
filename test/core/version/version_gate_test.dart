import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/version/app_build_info.dart';
import 'package:logistics_app/core/version/app_version.dart';
import 'package:logistics_app/core/version/version_gate.dart';

ProviderContainer _container({String version = '1.4.2'}) {
  final container = ProviderContainer(
    overrides: [
      appBuildInfoLoaderProvider.overrideWithValue(
        () async => AppBuildInfo(version: version, buildNumber: '42'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _loaded(ProviderContainer c) async {
  c.read(versionGateProvider);
  await c.read(appBuildInfoProvider.notifier).ensureLoaded();
}

void main() {
  test('carga la versión instalada', () async {
    final c = _container();
    await _loaded(c);
    expect(c.read(appBuildInfoProvider)?.buildNumber, '42');
    expect(c.read(versionGateProvider).current, const AppVersion(1, 4, 2));
    expect(c.read(versionGateProvider).mustUpdate, isFalse);
  });

  test('bloquea si la mínima es mayor a la instalada', () async {
    final c = _container();
    await _loaded(c);
    c.read(versionGateProvider.notifier).reportMinVersion('1.5.0');
    expect(c.read(versionGateProvider).mustUpdate, isTrue);
  });

  test('no bloquea con mínima igual o menor', () async {
    final c = _container();
    await _loaded(c);
    final gate = c.read(versionGateProvider.notifier);
    gate.reportMinVersion('1.4.2');
    expect(c.read(versionGateProvider).mustUpdate, isFalse);
    gate.reportMinVersion('1.0.0');
    expect(c.read(versionGateProvider).mustUpdate, isFalse);
  });

  test('la mínima puede bajar (rollback del backend) y desbloquear', () async {
    final c = _container();
    await _loaded(c);
    final gate = c.read(versionGateProvider.notifier);
    gate.reportMinVersion('2.0.0');
    expect(c.read(versionGateProvider).mustUpdate, isTrue);
    gate.reportMinVersion('1.0.0');
    expect(c.read(versionGateProvider).mustUpdate, isFalse);
  });

  test('valores inválidos se ignoran sin bloquear', () async {
    final c = _container();
    await _loaded(c);
    c.read(versionGateProvider.notifier).reportMinVersion('basura');
    expect(c.read(versionGateProvider).minRequired, isNull);
    expect(c.read(versionGateProvider).mustUpdate, isFalse);
  });

  test('sin versión instalada conocida no bloquea por mínima', () {
    final c = _container(version: 'desconocida');
    c.read(versionGateProvider.notifier).reportMinVersion('9.0.0');
    expect(c.read(versionGateProvider).mustUpdate, isFalse);
  });

  test('la mínima informada antes de cargar la versión se conserva', () async {
    final c = _container();
    c.read(versionGateProvider.notifier).reportMinVersion('1.5.0');
    expect(c.read(versionGateProvider).mustUpdate, isFalse);
    await c.read(appBuildInfoProvider.notifier).ensureLoaded();
    expect(c.read(versionGateProvider).minRequired, const AppVersion(1, 5));
    expect(c.read(versionGateProvider).mustUpdate, isTrue);
  });

  test('426 bloquea aunque no haya mínima', () {
    final c = _container();
    c.read(versionGateProvider.notifier).reportUpgradeRequired();
    expect(c.read(versionGateProvider).mustUpdate, isTrue);
  });

  test('si la plataforma falla, queda sin versión y sin lanzar', () async {
    final c = ProviderContainer(
      overrides: [
        appBuildInfoLoaderProvider.overrideWithValue(
          () async => throw StateError('sin plataforma'),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(appBuildInfoProvider.notifier).ensureLoaded();
    expect(c.read(appBuildInfoProvider), isNull);
  });
}
