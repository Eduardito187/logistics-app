import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/office/label_raster.dart';
import 'package:logistics_app/core/printing/render/offscreen_widget_renderer.dart';
import 'package:logistics_app/core/printing/render/test_page_renderer.dart';

// Dibujo FUERA de pantalla para impresoras de oficina: un widget a raster a
// los dpi pedidos y la hoja de prueba con PictureRecorder.

void main() {
  testWidgets('widget fuera de pantalla → raster al tamaño físico', (
    tester,
  ) async {
    final raster = await tester.runAsync(
      () => renderWidgetToRaster(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 50,
            height: 100,
            child: ColoredBox(color: Colors.black),
          ),
        ),
        logicalSize: const Size(100, 100),
        view: tester.view,
        dpi: 200,
      ),
    );

    expect(raster, isA<LabelRaster>());
    // 1" × 1" a 200 dpi.
    expect(raster!.width, 200);
    expect(raster.height, 200);
    expect(raster.dpi, 200);
    expect(raster.at(10, 10), lessThan(30)); // mitad izquierda negra
    expect(raster.at(190, 10), greaterThan(225)); // mitad derecha blanca
  });

  testWidgets('hoja de prueba: 4" × 3" con tinta', (tester) async {
    final raster = await tester.runAsync(
      () => renderTestPage(
        deviceName: 'Teléfono de prueba',
        now: DateTime(2026, 11, 11, 9, 5),
        dpi: 100,
      ),
    );

    expect(raster!.width, 400);
    expect(raster.height, 300);
    // Hay trazo (borde/texto) y fondo blanco. No se mira el centro: en tests
    // el texto usa la fuente Ahem (cada glifo es un bloque negro) y la última
    // línea, al partirse en dos, cae justo sobre el centro.
    expect(raster.pixels.any((v) => v < 100), isTrue);
    expect(raster.pixels.any((v) => v > 225), isTrue);
    expect(raster.at(2, 2), greaterThan(225)); // margen fuera del borde
    expect(raster.at(6, 150), lessThan(100)); // borde izquierdo (x 4.5–7.5)
    expect(raster.at(200, 15), greaterThan(225)); // entre borde y título
  });
}
