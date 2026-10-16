import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/scanning/scan_frame.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../support/screen_sizes.dart';

// Escáner para teléfonos de 1 GB: resolución moderada, análisis espaciado,
// sin copiar cada cuadro a Dart; y el recuadro guía entra en pantallas chicas.
void main() {
  group('createScannerController', () {
    test('pide 1280x720, detección espaciada y sin imagen de retorno', () {
      final controller = createScannerController(const [BarcodeFormat.qrCode]);
      addTearDown(controller.dispose);

      expect(controller.cameraResolution, kScannerCameraResolution);
      expect(kScannerCameraResolution, const Size(1280, 720));
      expect(controller.detectionSpeed, DetectionSpeed.normal);
      expect(controller.detectionTimeoutMs, kScannerDetectionTimeoutMs);
      expect(controller.returnImage, isFalse);
      expect(controller.formats, const [BarcodeFormat.qrCode]);
    });
  });

  group('ScanFrame.sideFor', () {
    test('tope de 260 dp en teléfonos típicos y tablets', () {
      expect(ScanFrame.sideFor(const Size(320, 568)), ScanFrame.maxSide);
      expect(ScanFrame.sideFor(const Size(360, 780)), ScanFrame.maxSide);
      expect(ScanFrame.sideFor(const Size(800, 1280)), ScanFrame.maxSide);
    });

    test('se achica en pantallas angostas y en horizontal', () {
      // 280 de ancho: 280 - 48 de margen.
      expect(ScanFrame.sideFor(const Size(280, 500)), closeTo(232, 0.01));
      // 568x320 horizontal: lo limita la altura (55 %).
      expect(ScanFrame.sideFor(const Size(568, 320)), closeTo(176, 0.01));
    });
  });

  final small = TestScreen.smallPhone.size;
  for (final size in [small, Size(small.height, small.width)]) {
    testWidgets('ScanFrame con ayuda larga no desborda en $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: withTextScale(
            Scaffold(
              body: ScanFrame(
                helper: 'Apunta al código de barras de la caja. ' * 4,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
