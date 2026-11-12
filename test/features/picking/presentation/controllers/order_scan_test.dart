import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/features/picking/domain/entities/scanned_order.dart';
import 'package:logistics_app/features/picking/presentation/controllers/order_scan.dart';

import '../../../../support/fake_label_resolver.dart';

// `orderFromScannedCode`: qué pedido abre lo que escaneó el preparador.
// QR firmado → su orderNumber (offline, sin resolver); Code128 → el backend
// (FakeLabelResolver); número con forma de pedido → ese; lo demás → rechazo.

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

/// QR real del vector Ed25519 compartido con el backend (pedido DM-260012345).
String _validQr() => _vector()['qr_content'] as String;

/// QR del vector con el campo `o` (pedido) reemplazado por [orderNumber].
String _qrWithOrder(String orderNumber) {
  final map = jsonDecode(_validQr()) as Map<String, dynamic>; // copia mutable
  map['o'] = orderNumber;
  return jsonEncode(map);
}

const _qrRejected = 'Esa etiqueta no es de DisTrack o está dañada.';
const _garbageRejected =
    'Ese código no es la etiqueta de un producto ni un número de pedido.';

/// Monta un `Consumer` para obtener un [WidgetRef] real con el resolver falso.
Future<WidgetRef> _ref(WidgetTester tester, LabelResolver resolver) async {
  late WidgetRef captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [labelResolverProvider.overrideWithValue(resolver)],
      child: Consumer(
        builder: (context, ref, _) {
          captured = ref;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void _expectFound(ScannedOrder result, String orderNumber) {
  expect(result.isFound, isTrue, reason: result.error);
  expect(result.orderNumber, orderNumber);
  expect(result.error, isNull);
}

void _expectRejected(ScannedOrder result, String message) {
  expect(result.isFound, isFalse);
  expect(result.orderNumber, isNull);
  expect(result.error, message);
}

void main() {
  group('QR firmado de un producto', () {
    testWidgets('abre el pedido del payload sin consultar al backend', (
      tester,
    ) async {
      final resolver = FakeLabelResolver();
      final ref = await _ref(tester, resolver);

      final result = await orderFromScannedCode(ref, _validQr());

      _expectFound(result, 'DM-260012345');
      expect(resolver.requested, isEmpty); // offline: no va a /resolve
    });

    testWidgets('funciona sin señal (resolver offline)', (tester) async {
      final ref = await _ref(tester, FakeLabelResolver(offline: true));

      final result = await orderFromScannedCode(ref, _validQr());

      _expectFound(result, 'DM-260012345');
    });

    testWidgets('recorta espacios alrededor del QR', (tester) async {
      final ref = await _ref(tester, FakeLabelResolver());

      final result = await orderFromScannedCode(ref, '  ${_validQr()}\n');

      _expectFound(result, 'DM-260012345');
    });

    testWidgets('recorta espacios del número dentro del payload', (
      tester,
    ) async {
      final ref = await _ref(tester, FakeLabelResolver());

      final result = await orderFromScannedCode(ref, _qrWithOrder(' DIS-9 '));

      _expectFound(result, 'DIS-9');
    });

    testWidgets('JSON roto → rechazo "no es de DisTrack o está dañada"', (
      tester,
    ) async {
      final resolver = FakeLabelResolver(echo: true);
      final ref = await _ref(tester, resolver);

      final result = await orderFromScannedCode(ref, '{"v":1,"t":"PKG",');

      _expectRejected(result, _qrRejected);
      // Un QR con forma de JSON NUNCA se manda a resolver online.
      expect(resolver.requested, isEmpty);
    });

    testWidgets('JSON válido pero sin los campos de etiqueta → rechazo', (
      tester,
    ) async {
      final resolver = FakeLabelResolver(echo: true);
      final ref = await _ref(tester, resolver);

      final result = await orderFromScannedCode(ref, '{"v":1}');

      _expectRejected(result, _qrRejected);
      expect(resolver.requested, isEmpty);
    });

    testWidgets('etiqueta con pedido sin forma de pedido → rechazo', (
      tester,
    ) async {
      final ref = await _ref(tester, FakeLabelResolver());

      final result = await orderFromScannedCode(
        ref,
        _qrWithOrder('pedido con espacios'),
      );

      _expectRejected(result, _qrRejected);
    });

    testWidgets('etiqueta con pedido vacío → rechazo', (tester) async {
      final ref = await _ref(tester, FakeLabelResolver());

      final result = await orderFromScannedCode(ref, _qrWithOrder(''));

      _expectRejected(result, _qrRejected);
    });
  });

  group('Code128 (label_id)', () {
    testWidgets('resuelto por el backend con order_number → ese pedido', (
      tester,
    ) async {
      final resolver = FakeLabelResolver(
        resolutions: {
          'LBL-01JB8': const LabelResolution(
            labelId: 'LBL-01JB8',
            resolved: true,
            unitId: 'unit-1',
            orderNumber: 'DIS-555',
          ),
        },
      );
      final ref = await _ref(tester, resolver);

      final result = await orderFromScannedCode(ref, 'LBL-01JB8');

      _expectFound(result, 'DIS-555');
      expect(resolver.requested, ['LBL-01JB8']);
    });

    testWidgets('el order_number resuelto se recorta', (tester) async {
      final ref = await _ref(
        tester,
        FakeLabelResolver(
          resolutions: {
            'LBL-2': const LabelResolution(
              labelId: 'LBL-2',
              resolved: true,
              orderNumber: '  DIS-556  ',
            ),
          },
        ),
      );

      final result = await orderFromScannedCode(ref, 'LBL-2');

      _expectFound(result, 'DIS-556');
    });

    testWidgets('no resuelto pero con forma de pedido → se usa como número', (
      tester,
    ) async {
      final resolver = FakeLabelResolver();
      final ref = await _ref(tester, resolver);

      final result = await orderFromScannedCode(ref, 'DIS-777');

      _expectFound(result, 'DIS-777');
      expect(resolver.requested, ['DIS-777']); // primero intentó resolver
    });

    testWidgets('sin señal y con forma de pedido → se usa como número', (
      tester,
    ) async {
      final ref = await _ref(tester, FakeLabelResolver(offline: true));

      final result = await orderFromScannedCode(ref, '  DIS-1  ');

      _expectFound(result, 'DIS-1');
    });

    testWidgets('resuelto SIN order_number → cae al código si es plausible', (
      tester,
    ) async {
      final ref = await _ref(
        tester,
        FakeLabelResolver(
          resolutions: {
            'LBL-3': const LabelResolution(
              labelId: 'LBL-3',
              resolved: true,
              unitId: 'unit-3',
            ),
          },
        ),
      );

      final result = await orderFromScannedCode(ref, 'LBL-3');

      _expectFound(result, 'LBL-3');
    });

    testWidgets('order_number resuelto sin forma de pedido no se usa', (
      tester,
    ) async {
      final ref = await _ref(
        tester,
        FakeLabelResolver(
          resolutions: {
            'LBL-4': const LabelResolution(
              labelId: 'LBL-4',
              resolved: true,
              orderNumber: '{"v":1}',
            ),
          },
        ),
      );

      final result = await orderFromScannedCode(ref, 'LBL-4');

      // Cae al paso 3: el propio código tiene forma de pedido.
      _expectFound(result, 'LBL-4');
    });

    testWidgets('resolved:false con order_number no se usa', (tester) async {
      final ref = await _ref(
        tester,
        FakeLabelResolver(
          resolutions: {
            'LBL-5': const LabelResolution(
              labelId: 'LBL-5',
              resolved: false,
              orderNumber: 'DIS-999',
            ),
          },
        ),
      );

      final result = await orderFromScannedCode(ref, 'LBL-5');

      _expectFound(result, 'LBL-5');
    });
  });

  group('basura', () {
    testWidgets('texto con espacios → rechazo', (tester) async {
      final ref = await _ref(tester, FakeLabelResolver());

      final result = await orderFromScannedCode(ref, 'hola mundo');

      _expectRejected(result, _garbageRejected);
    });

    testWidgets('URL → rechazo', (tester) async {
      final ref = await _ref(tester, FakeLabelResolver(offline: true));

      final result = await orderFromScannedCode(
        ref,
        'https://dismac.com.bo/p/1',
      );

      _expectRejected(result, _garbageRejected);
    });

    testWidgets('demasiado largo → rechazo', (tester) async {
      final ref = await _ref(tester, FakeLabelResolver());

      final result = await orderFromScannedCode(ref, 'A' * 41);

      _expectRejected(result, _garbageRejected);
    });

    testWidgets('vacío o solo espacios → "No se leyó ningún código."', (
      tester,
    ) async {
      final resolver = FakeLabelResolver(echo: true);
      final ref = await _ref(tester, resolver);

      _expectRejected(
        await orderFromScannedCode(ref, ''),
        'No se leyó ningún código.',
      );
      _expectRejected(
        await orderFromScannedCode(ref, '   '),
        'No se leyó ningún código.',
      );
      expect(resolver.requested, isEmpty);
    });
  });
}
