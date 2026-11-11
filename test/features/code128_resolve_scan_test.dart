import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/carrier_scan_support.dart';
import 'package:logistics_app/features/driver/presentation/driver_common.dart';

import '../support/fake_label_resolver.dart';

// Un Code128 escaneado ES el `label_id` (sin firma): chofer (`verifyUnitLabel`)
// y transportista (`verifyLabelQr`) lo resuelven ONLINE y aceptan/rechazan
// según el backend. Un valor que no es QR firmado cae a este camino.

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

List<Override> _overrides(FakeLabelResolver resolver) => [
  // Sin claves: un valor que no es QR firmado cae directo al camino Code128.
  labelScannerProvider.overrideWithValue(LabelScanner(null)),
  labelResolverProvider.overrideWithValue(resolver),
];

void main() {
  group('Chofer verifyUnitLabel (Code128)', () {
    testWidgets('resuelto → devuelve el unit_id del backend', (tester) async {
      final resolver = FakeLabelResolver(
        resolutions: {
          'LBL-1': const LabelResolution(
            labelId: 'LBL-1',
            resolved: true,
            unitId: 'U-REAL',
          ),
        },
      );
      await _withRef(tester, _overrides(resolver), (ref) async {
        expect(await verifyUnitLabel(ref, 'LBL-1'), 'U-REAL');
      });
    });

    testWidgets('no reconocido / anulado / sin señal → null', (tester) async {
      final resolver = FakeLabelResolver(
        resolutions: {
          'LBL-ANULADA': const LabelResolution(
            labelId: 'LBL-ANULADA',
            resolved: true,
            unitId: 'U-7',
            revoked: true,
          ),
        },
      );
      await _withRef(tester, _overrides(resolver), (ref) async {
        expect(await verifyUnitLabel(ref, 'DESCONOCIDO'), isNull);
        expect(await verifyUnitLabel(ref, 'LBL-ANULADA'), isNull);
      });
      final offline = FakeLabelResolver(offline: true);
      await _withRef(tester, _overrides(offline), (ref) async {
        expect(await verifyUnitLabel(ref, 'LBL-SIN-RED'), isNull);
      });
    });
  });

  group('Transportista verifyLabelQr (Code128)', () {
    testWidgets('resuelto → etiqueta con unit_id, pedido y sku', (
      tester,
    ) async {
      final resolver = FakeLabelResolver(
        resolutions: {
          'LBL-9': const LabelResolution(
            labelId: 'LBL-9',
            resolved: true,
            unitId: 'U-9',
            orderNumber: '100000452',
            sku: 'BAS-QUEEN',
          ),
        },
      );
      await _withRef(tester, _overrides(resolver), (ref) async {
        final check = await verifyLabelQr(ref, 'LBL-9');
        expect(check.error, isNull);
        expect(check.label!.unitId, 'U-9');
        expect(check.label!.shipmentId, '100000452'); // order_number
        expect(check.label!.sku, 'BAS-QUEEN');
      });
    });

    testWidgets('no reconocido → "Etiqueta no reconocida"', (tester) async {
      final resolver = FakeLabelResolver();
      await _withRef(tester, _overrides(resolver), (ref) async {
        final check = await verifyLabelQr(ref, 'NOPE');
        expect(check.label, isNull);
        expect(check.error, 'Etiqueta no reconocida');
      });
    });

    testWidgets('anulada → "Etiqueta anulada"', (tester) async {
      final resolver = FakeLabelResolver(
        resolutions: {
          'LBL-A': const LabelResolution(
            labelId: 'LBL-A',
            resolved: true,
            unitId: 'U-1',
            revoked: true,
          ),
        },
      );
      await _withRef(tester, _overrides(resolver), (ref) async {
        final check = await verifyLabelQr(ref, 'LBL-A');
        expect(check.label, isNull);
        expect(check.error, 'Etiqueta anulada');
      });
    });

    testWidgets('sin señal → "Sin señal para validar la etiqueta"', (
      tester,
    ) async {
      final resolver = FakeLabelResolver(offline: true);
      await _withRef(tester, _overrides(resolver), (ref) async {
        final check = await verifyLabelQr(ref, 'LBL-X');
        expect(check.label, isNull);
        expect(check.error, 'Sin señal para validar la etiqueta');
      });
    });
  });
}
