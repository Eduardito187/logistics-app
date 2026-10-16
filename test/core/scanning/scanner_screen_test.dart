// Se mockea mobile_scanner a través de su PlatformInterface. Los tipos
// StartOptions y MobileScannerViewAttributes no se reexportan desde el paquete
// público, así que se importan desde src/ solo para el mock de test.
// ignore_for_file: implementation_imports, depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ScannerScreen envuelve MobileScanner: lee el PRIMER código no vacío y lo
// devuelve con Navigator.pop; un escaneo ya manejado no se procesa dos veces.

class _FakeScannerPlatform extends MobileScannerPlatform
    with MockPlatformInterfaceMixin {
  final StreamController<BarcodeCapture?> barcodes =
      StreamController<BarcodeCapture?>.broadcast();
  final StreamController<TorchState> torch =
      StreamController<TorchState>.broadcast();
  final StreamController<double> zoom = StreamController<double>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => torch.stream;

  @override
  Stream<double> get zoomScaleStateStream => zoom.stream;

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    // No hay cámara en test: se falla el arranque. El controller lo captura y
    // deja la vista en estado de error (recuadro negro), pero la suscripción a
    // los códigos ya quedó activa, que es lo que se ejercita aquí.
    throw const MobileScannerException(
      errorCode: MobileScannerErrorCode.genericError,
    );
  }

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await barcodes.close();
    await torch.close();
    await zoom.close();
  }
}

/// Monta un host con un botón que abre el scanner y guarda el resultado.
Future<void> _openScanner(
  WidgetTester tester, {
  required void Function(String?) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async => onResult(await scanCode(ctx)),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  late _FakeScannerPlatform platform;

  setUp(() {
    platform = _FakeScannerPlatform();
    MobileScannerPlatform.instance = platform;
  });

  testWidgets('monta el scanner con título y acciones de cámara', (
    tester,
  ) async {
    await _openScanner(tester, onResult: (_) {});

    expect(find.text('Escanear'), findsOneWidget);
    expect(find.byIcon(Icons.flash_on), findsOneWidget);
    expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
  });

  testWidgets('devuelve el primer código no vacío leído', (tester) async {
    String? result;
    var completed = false;
    await _openScanner(
      tester,
      onResult: (r) {
        result = r;
        completed = true;
      },
    );

    platform.barcodes.add(
      const BarcodeCapture(
        barcodes: [
          Barcode(rawValue: null),
          Barcode(rawValue: ''),
          Barcode(rawValue: 'EAN-123'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, 'EAN-123');
    expect(find.text('Escanear'), findsNothing); // el scanner se cerró
  });

  testWidgets('no cierra si la captura no trae ningún código válido', (
    tester,
  ) async {
    String? result;
    var completed = false;
    await _openScanner(
      tester,
      onResult: (r) {
        result = r;
        completed = true;
      },
    );

    platform.barcodes.add(
      const BarcodeCapture(
        barcodes: [
          Barcode(rawValue: null),
          Barcode(rawValue: ''),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    expect(result, isNull);
    expect(find.text('Escanear'), findsOneWidget); // sigue abierto
  });

  testWidgets('solo procesa el primer código (guarda _handled)', (
    tester,
  ) async {
    String? result;
    await _openScanner(tester, onResult: (r) => result = r);

    platform.barcodes.add(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'PRIMERO')]),
    );
    platform.barcodes.add(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'SEGUNDO')]),
    );
    await tester.pumpAndSettle();

    expect(result, 'PRIMERO');
  });
}
