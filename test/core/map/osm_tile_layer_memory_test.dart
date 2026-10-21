import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:logistics_app/core/map/osm_tile_layer.dart';

// La capa de tiles va afinada para teléfonos de 1 GB: sin retina, buffers
// bajos, zoom nativo acotado y sin fundido; y OsmTileLayer no se recrea al
// reconstruir el padre.
void main() {
  group('buildOsmTileLayer (memoria)', () {
    final layer = buildOsmTileLayer();

    test('sin retina (ni @2x del servidor ni simulada)', () {
      expect(layer.resolvedRetinaMode, RetinaMode.disabled);
    });

    test('buffers de tiles bajos', () {
      expect(layer.keepBuffer, kMapKeepBuffer);
      expect(layer.panBuffer, kMapPanBuffer);
      expect(kMapKeepBuffer, lessThan(2)); // default de flutter_map: 2
      expect(kMapPanBuffer, 0);
    });

    test('zoom nativo acotado a 18 y zoom máximo 19 (sobre-escala)', () {
      expect(layer.maxNativeZoom, 18);
      expect(layer.maxZoom, 19);
    });

    test('se puede ajustar el zoom nativo (servidor self-host)', () {
      final custom = buildOsmTileLayer(maxNativeZoom: 17, maxZoom: 18);
      expect(custom.maxNativeZoom, 17);
      expect(custom.maxZoom, 18);
    });

    test('tiles sin fundido y errores descartados fuera de pantalla', () {
      expect(layer.tileDisplay, isA<InstantaneousTileDisplay>());
      expect(
        layer.evictErrorTileStrategy,
        EvictErrorTileStrategy.notVisibleRespectMargin,
      );
    });
  });

  testWidgets('OsmTileLayer conserva la misma TileLayer al reconstruir', (
    tester,
  ) async {
    late StateSetter rebuild;
    var tick = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return SizedBox(
              // Mapa mínimo: en test los tiles responden 400 (sin red) y
              // flutter_map lo loguea; cuanto más chico, menos ruido.
              width: 8,
              height: 8,
              child: FlutterMap(
                key: const ValueKey('map'),
                options: const MapOptions(
                  initialCenter: LatLng(-16.5, -68.1),
                  initialZoom: 12,
                ),
                children: [
                  const OsmTileLayer(),
                  Text('tick $tick', textDirection: TextDirection.ltr),
                ],
              ),
            );
          },
        ),
      ),
    );
    final before = tester.widget<TileLayer>(find.byType(TileLayer));

    rebuild(() => tick++);
    await tester.pump();

    expect(find.text('tick 1'), findsOneWidget);
    final after = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(identical(before, after), isTrue);
    expect(after.urlTemplate, buildOsmTileLayer().urlTemplate);
  });
}
