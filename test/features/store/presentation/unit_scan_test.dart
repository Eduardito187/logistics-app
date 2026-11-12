import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/features/store/presentation/unit_scan.dart';

import '../../../support/fake_label_resolver.dart';

// `resolveUnitScan` convierte un QR en un `UnitScan` (id del producto + si la firma
// se verificó offline). Nunca lanza: cae al texto crudo si el QR no es una
// etiqueta firmada. Se apoya en el vector Ed25519 compartido con el backend.

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

const _expectedUnitId = '01JB8ZQ4X7K2M9N5P6R7S8T9VW';

/// Monta un Consumer para capturar un [WidgetRef] con los overrides dados y
/// ejecuta [body] con él.
Future<void> _withRef(
  WidgetTester tester,
  List<Override> overrides,
  Future<void> Function(WidgetRef ref) body,
) async {
  late WidgetRef captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, _) {
          captured = ref;
          return const SizedBox();
        },
      ),
    ),
  );
  await body(captured);
}

/// Scanner con la clave pública correcta del vector (puede verificar).
LabelScanner _scannerWithKey(int keyId) {
  final vector = _vector();
  final key = base64.decode(vector['public_key_base64'] as String);
  return LabelScanner(LabelVerifier({keyId: key}));
}

void main() {
  testWidgets(
    'QR firmado válido: devuelve el id del producto y verified=true',
    (tester) async {
      final qr = _vector()['qr_content'] as String;
      await _withRef(
        tester,
        [labelScannerProvider.overrideWithValue(_scannerWithKey(1))],
        (ref) async {
          final scan = await resolveUnitScan(ref, qr);
          expect(scan.unitId, _expectedUnitId);
          expect(scan.verified, isTrue);
        },
      );
    },
  );

  testWidgets(
    'QR manipulado: id del producto pero verified=false (firma mala)',
    (tester) async {
      final qr = _vector()['tampered_qr_content'] as String;
      await _withRef(
        tester,
        [labelScannerProvider.overrideWithValue(_scannerWithKey(1))],
        (ref) async {
          final scan = await resolveUnitScan(ref, qr);
          expect(scan.unitId, _expectedUnitId);
          expect(scan.verified, isFalse);
        },
      );
    },
  );

  testWidgets(
    'clave desconocida: verified=false aunque el QR esté bien formado',
    (tester) async {
      final qr = _vector()['qr_content'] as String;
      // El scanner puede verificar, pero no tiene la clave 1 (solo la 99).
      await _withRef(
        tester,
        [labelScannerProvider.overrideWithValue(_scannerWithKey(99))],
        (ref) async {
          final scan = await resolveUnitScan(ref, qr);
          expect(scan.unitId, _expectedUnitId);
          expect(scan.verified, isFalse);
        },
      );
    },
  );

  testWidgets('sin claves configuradas: parsea el id pero verified=null', (
    tester,
  ) async {
    final qr = _vector()['qr_content'] as String;
    await _withRef(
      tester,
      [labelScannerProvider.overrideWithValue(LabelScanner(null))],
      (ref) async {
        final scan = await resolveUnitScan(ref, qr);
        expect(scan.unitId, _expectedUnitId);
        expect(scan.verified, isNull);
      },
    );
  });

  testWidgets(
    'Code128 (no es QR firmado): resuelve el label_id ONLINE y devuelve el '
    'unit_id del backend, verified=null (sin firma)',
    (tester) async {
      final resolver = FakeLabelResolver(
        resolutions: {
          'LBL-001': const LabelResolution(
            labelId: 'LBL-001',
            resolved: true,
            unitId: 'U-REAL-9',
          ),
        },
      );
      await _withRef(
        tester,
        [
          labelScannerProvider.overrideWithValue(_scannerWithKey(1)),
          labelResolverProvider.overrideWithValue(resolver),
        ],
        (ref) async {
          final scan = await resolveUnitScan(ref, 'LBL-001');
          expect(scan.unitId, 'U-REAL-9'); // el unit_id real, no el label_id
          expect(scan.verified, isNull); // sin firma (resuelto por servidor)
          expect(scan.online, isTrue);
          expect(resolver.requested, ['LBL-001']);
        },
      );
    },
  );

  testWidgets('Code128 no reconocido (resolved:false): verified=false', (
    tester,
  ) async {
    final resolver = FakeLabelResolver(); // nada sembrado → resolved:false
    await _withRef(
      tester,
      [
        labelScannerProvider.overrideWithValue(_scannerWithKey(1)),
        labelResolverProvider.overrideWithValue(resolver),
      ],
      (ref) async {
        final scan = await resolveUnitScan(ref, 'DESCONOCIDO');
        expect(scan.verified, isFalse);
        expect(scan.online, isTrue);
        expect(scan.revoked, isFalse);
        expect(unitScanShortError(scan), 'Etiqueta no reconocida');
      },
    );
  });

  testWidgets('etiqueta permanente: si resuelve se ACEPTA (no hay "anulada")', (
    tester,
  ) async {
    // Etiquetas globales y permanentes: nada se anula. Aunque llegue el flag
    // legacy `revoked`, una etiqueta que resuelve es aceptable (verified=null).
    final resolver = FakeLabelResolver(
      resolutions: {
        'LBL-X': const LabelResolution(
          labelId: 'LBL-X',
          resolved: true,
          unitId: 'U-7',
          revoked: true,
        ),
      },
    );
    await _withRef(
      tester,
      [
        labelScannerProvider.overrideWithValue(_scannerWithKey(1)),
        labelResolverProvider.overrideWithValue(resolver),
      ],
      (ref) async {
        final scan = await resolveUnitScan(ref, 'LBL-X');
        expect(scan.unitId, 'U-7');
        expect(scan.verified, isNull); // resuelto por servidor, aceptado
      },
    );
  });

  testWidgets('Code128 sin señal: no validable → verified=false, unreachable', (
    tester,
  ) async {
    final resolver = FakeLabelResolver(offline: true);
    await _withRef(
      tester,
      [
        labelScannerProvider.overrideWithValue(_scannerWithKey(1)),
        labelResolverProvider.overrideWithValue(resolver),
      ],
      (ref) async {
        final scan = await resolveUnitScan(ref, 'LBL-SIN-RED');
        expect(scan.verified, isFalse);
        expect(scan.unreachable, isTrue);
        expect(unitScanShortError(scan), 'Sin señal para validar');
      },
    );
  });
}
