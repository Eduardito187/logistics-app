// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/map/map_launcher.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// openExternalNavigation abre la navegación externa sin Google. El esquema
// `geo:` solo se intenta en Android; en el host de los tests (Linux) siempre se
// cae al fallback de OpenStreetMap en el navegador. Se mockea
// url_launcher a través de su PlatformInterface.
//
// LIMITACIÓN: la rama Android (geo: + etiqueta, canLaunchUrl) no es ejercitable
// en `flutter test` porque Platform.isAndroid es false en el host; requiere
// prueba de integración en dispositivo.

class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool launchResult = true;
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return launchResult;
  }
}

void main() {
  late _FakeUrlLauncher launcher;

  setUp(() {
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

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
}
