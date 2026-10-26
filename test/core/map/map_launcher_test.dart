// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/map/map_launcher.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// openExternalNavigation abre la navegación externa sin Google. El esquema
// `geo:` solo se intenta en Android (se fuerza con
// debugDefaultTargetPlatformOverride); en otras plataformas se cae al fallback
// de OpenStreetMap en el navegador. Se mockea url_launcher a través de su
// PlatformInterface.

class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool launchResult = true;
  bool canLaunchResult = true;

  /// Respuesta de launchUrl por esquema (p. ej. 'geo' → false); si no está,
  /// usa [launchResult].
  final Map<String, bool> launchResultByScheme = {};
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return launchResultByScheme[Uri.parse(url).scheme] ?? launchResult;
  }
}

void main() {
  late _FakeUrlLauncher launcher;

  setUp(() {
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    // flutter_test simula Android por defecto: fuera del grupo Android se
    // fuerza otra plataforma para ejercitar el fallback.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('abre OpenStreetMap con mlat/mlon y zoom en el fallback', () async {
    final ok = await openExternalNavigation(-16.5, -68.15);

    expect(ok, isTrue);
    expect(launcher.launched, hasLength(1));
    expect(
      launcher.launched.single,
      'https://www.openstreetmap.org/?mlat=-16.5&mlon=-68.15#map=17/-16.5/-68.15',
    );
  });

  test('propaga false si no se pudo lanzar nada', () async {
    launcher.launchResult = false;
    final ok = await openExternalNavigation(1, 2, label: 'Tienda Centro');
    expect(ok, isFalse);
  });

  group('Android', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('lanza geo: con la etiqueta codificada y no usa OSM', () async {
      final ok = await openExternalNavigation(
        -16.5,
        -68.15,
        label: 'Tienda Centro',
      );

      expect(ok, isTrue);
      expect(launcher.launched, [
        'geo:-16.5,-68.15?q=-16.5,-68.15(Tienda%20Centro)',
      ]);
    });

    test('sin etiqueta el pin usa solo las coordenadas', () async {
      await openExternalNavigation(1, 2);
      expect(launcher.launched, ['geo:1.0,2.0?q=1.0,2.0']);
    });

    test('sin app que maneje geo: cae a OpenStreetMap', () async {
      launcher.canLaunchResult = false;
      final ok = await openExternalNavigation(1, 2);

      expect(ok, isTrue);
      expect(
        launcher.launched.single,
        startsWith('https://www.openstreetmap.org/'),
      );
    });

    test('si geo: no se pudo lanzar, intenta OpenStreetMap', () async {
      launcher.launchResultByScheme['geo'] = false;
      final ok = await openExternalNavigation(1, 2);

      expect(ok, isTrue);
      expect(launcher.launched, hasLength(2));
      expect(
        launcher.launched.last,
        startsWith('https://www.openstreetmap.org/'),
      );
    });
  });
}
