import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/store/domain/usecases/record_pod.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../support/fake_code_scanner.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';
import '../../../support/button_finders.dart';

// Entrega en mostrador: flujos escaneo -> submit. El escáner de cámara se
// reemplaza con `FakeCodeScanner` (vía `codeScannerProvider`) y el caso de uso
// `RecordPod` con un fake que registra las llamadas (sin cola ni GPS).

final _shipment = shipment(customerName: 'Ana Pérez');

const _signedUnitId = '01JB8ZQ4X7K2M9N5P6R7S8T9VW';

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

/// Scanner de etiquetas con la clave pública del vector registrada en [keyId].
LabelScanner _scannerWithKey(int keyId) {
  final key = base64.decode(_vector()['public_key_base64'] as String);
  return LabelScanner(LabelVerifier({keyId: key}));
}

/// Caso de uso falso: registra cada POD y devuelve [outcome].
class _FakeRecordPod extends RecordPod {
  _FakeRecordPod(super.ref, this.calls, this.outcome);

  final List<Map<String, String?>> calls;
  final SubmitOutcome outcome;

  @override
  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String confirmation,
    required String customerName,
    String? photoPath,
  }) async {
    calls.add({
      'shipmentId': shipmentId,
      'unitId': unitId,
      'confirmation': confirmation,
      'customerName': customerName,
      'photoPath': photoPath,
    });
    return outcome;
  }
}

class _Harness {
  final calls = <Map<String, String?>>[];
  late FakeCodeScanner scanner;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required List<String?> codes,
  List<UnitTracking>? units,
  LabelScanner? labelScanner,
  SubmitOutcome outcome = SubmitOutcome.sent,
}) async {
  // Superficie alta: el ListView es perezoso y en 800x600 deja botones fuera.
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness()..scanner = FakeCodeScanner(codes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        shipmentUnitsProvider(_shipment.id).overrideWith(
          (ref) async =>
              units ?? [unit(unitId: 'unit-1'), unit(unitId: 'unit-2')],
        ),
        codeScannerProvider.overrideWithValue(h.scanner.call),
        labelScannerProvider.overrideWithValue(
          labelScanner ?? LabelScanner(null),
        ),
        recordPodProvider.overrideWith(
          (ref) => _FakeRecordPod(ref, h.calls, outcome),
        ),
      ],
      child: MaterialApp(home: PickupPodScreen(shipment: _shipment)),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

final _confirmationField = find.widgetWithText(
  TextField,
  'QR del cliente o documento',
);

Future<void> _typeConfirmation(WidgetTester tester, String text) async {
  await tester.enterText(_confirmationField, text);
  await tester.pumpAndSettle();
}

Future<void> _tapDeliver(WidgetTester tester) async {
  await tester.tap(
    findButtonWithText<FilledButton>('Escanear y entregar bulto'),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('QR del cliente (confirmación)', () {
    testWidgets('escanear llena la confirmación y habilita la entrega', (
      tester,
    ) async {
      final h = await _pump(tester, codes: ['CI-12345678']);

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();

      expect(h.scanner.requestedTitles, ['QR del cliente']);
      expect(
        tester.widget<TextField>(_confirmationField).controller!.text,
        'CI-12345678',
      );
      expect(
        find.text('Primero captura la confirmación del cliente.'),
        findsNothing,
      );
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Escanear y entregar bulto'),
      );
      expect(button.onPressed, isNotNull);
      // Escanear la confirmación no registra ninguna entrega.
      expect(h.calls, isEmpty);
    });

    testWidgets('cancelar deja la confirmación vacía y la entrega bloqueada', (
      tester,
    ) async {
      final h = await _pump(tester, codes: [null]);

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();

      expect(h.scanner.requestedTitles, hasLength(1));
      expect(tester.widget<TextField>(_confirmationField).controller!.text, '');
      final button = tester.widget<FilledButton>(
        findButtonWithText<FilledButton>('Escanear y entregar bulto'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('cancelar no pisa una confirmación ya escrita', (tester) async {
      await _pump(tester, codes: [null]);
      await _typeConfirmation(tester, 'CI-999');

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(_confirmationField).controller!.text,
        'CI-999',
      );
    });
  });

  group('escanear y entregar bulto', () {
    testWidgets(
      'camino feliz: registra el POD del bulto y lo marca entregado',
      (tester) async {
        final h = await _pump(tester, codes: ['unit-1']);
        await _typeConfirmation(tester, '  CI-12345678  ');

        await _tapDeliver(tester);

        expect(h.scanner.requestedTitles, ['Escanear bulto']);
        expect(h.scanner.requestedFormats.single, [BarcodeFormat.qrCode]);
        expect(h.calls, [
          {
            'shipmentId': _shipment.id,
            'unitId': 'unit-1',
            // La confirmación se envía recortada.
            'confirmation': 'CI-12345678',
            'customerName': 'Ana Pérez',
            'photoPath': null,
          },
        ]);
        expect(find.text('Registrado.'), findsOneWidget);
        expect(find.text('Entregados 1 de 2 bulto(s).'), findsOneWidget);
        expect(find.text('Entregado'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);
      },
    );

    testWidgets('confirmación escaneada viaja en el POD', (tester) async {
      final h = await _pump(tester, codes: ['QR-CLIENTE-7', 'unit-2']);

      await tester.tap(
        findButtonWithText<OutlinedButton>('Escanear QR del cliente'),
      );
      await tester.pumpAndSettle();
      await _tapDeliver(tester);

      expect(h.scanner.requestedTitles, ['QR del cliente', 'Escanear bulto']);
      expect(h.calls.single['unitId'], 'unit-2');
      expect(h.calls.single['confirmation'], 'QR-CLIENTE-7');
    });

    testWidgets('sin conexión: avisa que quedó en cola y lo marca entregado', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        codes: ['unit-1'],
        outcome: SubmitOutcome.queued,
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls, hasLength(1));
      expect(find.text('Registrado.'), findsOneWidget);
      expect(find.text('Entregados 1 de 2 bulto(s).'), findsOneWidget);
    });

    testWidgets('cancelar el escáner no registra nada', (tester) async {
      final h = await _pump(tester, codes: [null]);
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.scanner.requestedTitles, hasLength(1));
      expect(h.calls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Entregados 0 de 2 bulto(s).'), findsOneWidget);
    });

    testWidgets('etiqueta firmada válida: entrega con el id del payload', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        codes: [_vector()['qr_content'] as String],
        labelScanner: _scannerWithKey(1),
        units: [unit(unitId: _signedUnitId, label: 'B1')],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls.single['unitId'], _signedUnitId);
      expect(find.text('Entregados 1 de 1 bulto(s).'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
    });

    testWidgets('etiqueta con firma inválida: avisa en rojo y no entrega', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        codes: [_vector()['tampered_qr_content'] as String],
        labelScanner: _scannerWithKey(1),
        units: [unit(unitId: _signedUnitId)],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls, isEmpty);
      expect(
        find.text('Firma inválida: etiqueta editada o falsa.'),
        findsOneWidget,
      );
      expect(find.text('Entregados 0 de 1 bulto(s).'), findsOneWidget);
    });

    testWidgets('etiqueta de clave desconocida: avisa y no entrega', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        codes: [_vector()['qr_content'] as String],
        labelScanner: _scannerWithKey(99),
        units: [unit(unitId: _signedUnitId)],
      );
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);

      expect(h.calls, isEmpty);
      expect(
        find.text('Etiqueta de una clave desconocida: no se puede verificar.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'bulto ajeno al envío: no registra el POD ni cuenta como entregado',
      (tester) async {
        final h = await _pump(tester, codes: ['unit-de-otro-envio']);
        await _typeConfirmation(tester, 'CI-1');

        await _tapDeliver(tester);

        // Entregar al cliente un bulto que no es de su pedido debe frenarse.
        expect(h.calls, isEmpty);
        expect(find.text('Entregados 0 de 2 bulto(s).'), findsOneWidget);
      },
    );

    testWidgets('bulto ya entregado: no registra un segundo POD', (
      tester,
    ) async {
      final h = await _pump(tester, codes: ['unit-1', 'unit-1']);
      await _typeConfirmation(tester, 'CI-1');

      await _tapDeliver(tester);
      await _tapDeliver(tester);

      expect(h.calls, hasLength(1));
      expect(find.text('Entregados 1 de 2 bulto(s).'), findsOneWidget);
    });
  });
}
