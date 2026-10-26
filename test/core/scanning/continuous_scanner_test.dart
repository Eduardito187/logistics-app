// Se mockea mobile_scanner a través de su PlatformInterface (igual que
// scanner_screen_test). Los tipos StartOptions y MobileScannerViewAttributes no
// se reexportan desde el paquete público: se importan desde src/ solo acá.
// ignore_for_file: implementation_imports, depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Escaneo continuo: la cámara queda abierta entre bultos, cada código llama a
// onCode, se muestra el aviso sobre la cámara, el mismo código repetido en
// < 2 s se ignora y "Terminar" cierra.

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
    throw const MobileScannerException(
      errorCode: MobileScannerErrorCode.genericError,
    );
  }

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> stop() async {}

  // No se cierran los streams: el dispose del controller del test anterior
  // corre en diferido y caería sobre la instancia del test siguiente.
  @override
  Future<void> dispose() async {}

  void read(String code) =>
      barcodes.add(BarcodeCapture(barcodes: [Barcode(rawValue: code)]));
}

void main() {
  late _FakeScannerPlatform platform;
  late DateTime now;

  setUp(() {
    platform = _FakeScannerPlatform();
    MobileScannerPlatform.instance = platform;
    now = DateTime(2026, 10, 20, 9);
  });

  /// Abre la pantalla continua dentro de una ruta (para probar "Terminar").
  Future<void> open(
    WidgetTester tester, {
    required ScanCodeHandler onCode,
    void Function()? onClosed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                await Navigator.of(ctx).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ContinuousScannerScreen(
                      title: 'Cargar bultos',
                      helper: 'Apuntá a la etiqueta',
                      onCode: onCode,
                      now: () => now,
                    ),
                  ),
                );
                onClosed?.call();
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  test('ScanFeedback.ok / .error', () {
    const ok = ScanFeedback.ok('Registrado');
    const error = ScanFeedback.error('Ajeno');
    expect(ok.ok, isTrue);
    expect(ok.message, 'Registrado');
    expect(error.ok, isFalse);
    expect(error.message, 'Ajeno');
  });

  testWidgets('varios bultos sin cerrar la cámara, con aviso y contador', (
    tester,
  ) async {
    final codes = <String>[];
    await open(
      tester,
      onCode: (code) async {
        codes.add(code);
        return code == 'MALO'
            ? const ScanFeedback.error('No es de esta ruta')
            : ScanFeedback.ok('Bulto $code registrado');
      },
    );

    expect(find.text('Cargar bultos'), findsOneWidget);
    expect(find.text('Terminar'), findsOneWidget);
    expect(find.text('0 registrados'), findsOneWidget);

    platform.read('A1');
    await tester.pump();
    await tester.pump();
    expect(find.text('Bulto A1 registrado'), findsOneWidget);
    expect(find.text('1 registrado'), findsOneWidget);

    now = now.add(const Duration(milliseconds: 300));
    platform.read('B2');
    await tester.pump();
    await tester.pump();
    expect(find.text('Bulto B2 registrado'), findsOneWidget);
    expect(find.text('2 registrados'), findsOneWidget);

    now = now.add(const Duration(milliseconds: 300));
    platform.read('MALO');
    await tester.pump();
    await tester.pump();
    expect(find.text('No es de esta ruta'), findsOneWidget);
    // El error no suma al contador.
    expect(find.text('2 registrados'), findsOneWidget);

    expect(codes, ['A1', 'B2', 'MALO']);
    // La cámara sigue abierta.
    expect(find.byType(ContinuousScannerScreen), findsOneWidget);

    // El aviso se oculta solo.
    await tester.pump(kContinuousScanFeedbackVisible);
    expect(find.text('No es de esta ruta'), findsNothing);
  });

  testWidgets('el mismo código repetido en < 2 s se ignora', (tester) async {
    final codes = <String>[];
    await open(
      tester,
      onCode: (code) async {
        codes.add(code);
        return const ScanFeedback.ok('ok');
      },
    );

    platform.read('A1');
    await tester.pump();
    await tester.pump();
    now = now.add(const Duration(milliseconds: 500));
    platform.read('A1');
    await tester.pump();
    now = now.add(const Duration(milliseconds: 1200));
    platform.read('A1');
    await tester.pump();
    expect(codes, ['A1']);

    // Pasada la ventana sin verlo, se vuelve a procesar.
    now = now.add(const Duration(seconds: 3));
    platform.read('A1');
    await tester.pump();
    await tester.pump();
    expect(codes, ['A1', 'A1']);
  });

  testWidgets('no toma otro código mientras procesa uno', (tester) async {
    final codes = <String>[];
    final gate = Completer<ScanFeedback>();
    await open(
      tester,
      onCode: (code) {
        codes.add(code);
        return code == 'A1' ? gate.future : Future.value(ScanFeedback.ok(code));
      },
    );

    platform.read('A1');
    await tester.pump();
    platform.read('B2');
    await tester.pump();
    expect(codes, ['A1']);

    gate.complete(const ScanFeedback.ok('A1 listo'));
    await tester.pump();
    await tester.pump();
    expect(find.text('A1 listo'), findsOneWidget);

    platform.read('B2');
    await tester.pump();
    await tester.pump();
    expect(codes, ['A1', 'B2']);
  });

  testWidgets('si onCode lanza, muestra error y sigue escaneando', (
    tester,
  ) async {
    await open(tester, onCode: (code) async => throw StateError('boom'));

    platform.read('A1');
    await tester.pump();
    await tester.pump();
    expect(find.text('No se pudo registrar. Reintentá.'), findsOneWidget);
    expect(find.byType(ContinuousScannerScreen), findsOneWidget);
    // Deja terminar la doble vibración del aviso de error.
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('"Terminar" cierra la cámara', (tester) async {
    var closed = false;
    await open(
      tester,
      onCode: (_) async => const ScanFeedback.ok('ok'),
      onClosed: () => closed = true,
    );

    await tester.tap(find.text('Terminar'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(find.byType(ContinuousScannerScreen), findsNothing);
  });

  testWidgets('scanContinuous usa el override de continuousScannerProvider', (
    tester,
  ) async {
    final results = <ScanFeedback>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          continuousScannerProvider.overrideWithValue((
            context, {
            required title,
            helper,
            formats,
            required onCode,
          }) async {
            results.add(await onCode('X1'));
            results.add(await onCode('X2'));
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => scanContinuous(
                  ctx,
                  title: 'Descarga',
                  onCode: (code) async => ScanFeedback.ok(code),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(results.map((r) => r.message), ['X1', 'X2']);
    expect(find.byType(ContinuousScannerScreen), findsNothing);
  });

  testWidgets('scanContinuous sin override abre la cámara real', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => scanContinuous(
                ctx,
                title: 'Recepción',
                formats: const [BarcodeFormat.qrCode],
                onCode: (code) async => ScanFeedback.ok(code),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(ContinuousScannerScreen), findsOneWidget);
    expect(find.text('Recepción'), findsOneWidget);
  });
}
