import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/map/osm_tile_layer.dart';

// La capa de tiles central sale de AppConfig.mapTilesUrl (en test, sin
// --dart-define, es el tile público de OSM por defecto) y usa el User-Agent
// propio de la app que exigen los servidores de OSM.
void main() {
  test('buildOsmTileLayer usa la URL por defecto de OSM', () {
    final layer = buildOsmTileLayer();
    expect(layer.urlTemplate, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
  });

  test('buildOsmTileLayer fija el User-Agent propio de la app', () {
    // flutter_map no guarda `userAgentPackageName`: lo fusiona en el header
    // User-Agent del tile provider (solo fuera de web).
    final layer = buildOsmTileLayer();
    expect(kMapUserAgentPackageName, 'bo.com.dismac.logistics_app');
    expect(
      layer.tileProvider.headers['User-Agent'],
      'flutter_map (bo.com.dismac.logistics_app)',
    );
  });
}
