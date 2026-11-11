import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/picking/presentation/prepare_order_screen.dart';

import '../../../support/button_finders.dart';
import '../../../support/fake_code_scanner.dart';
import '../../../support/fake_label_resolver.dart';

// "Escanear producto": se escanea la etiqueta (QR o Code128) de cualquier
// producto y se abre SU pedido. Bug corregido: antes el JSON del QR se usaba
// como número ("Pedido {"v":1,…}" sin productos). La cámara se reemplaza con
// FakeCodeScanner (codeScannerProvider) y /resolve con FakeLabelResolver.

String _validQr() =>
    (jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
            as Map<String, dynamic>)['qr_content']
        as String;

/// Resolver que queda pendiente hasta que el test lo complete (para ver el
/// estado "Buscando el pedido…").
class _PendingResolver implements LabelResolver {
  final Completer<LabelResolution> completer = Completer<LabelResolution>();

  @override
  Future<LabelResolution> resolve(String labelId) => completer.future;
}

/// Monta la pantalla con un GoRouter de prueba. Devuelve las rutas visitadas
/// de preparación (lo que llegó como `orderNumber`).
Future<List<String>> _pump(
  WidgetTester tester,
  FakeCodeScanner scanner, {
  LabelResolver? resolver,
}) async {
  final opened = <String>[];
  final router = GoRouter(
    initialLocation: '/picking/prepare',
    routes: [
      GoRoute(
        path: '/picking/prepare',
        builder: (_, _) => const PrepareOrderScreen(),
      ),
      GoRoute(
        path: '/picking/order/:orderNumber',
        builder: (_, state) {
          final order = state.pathParameters['orderNumber']!;
          opened.add(order);
          return Scaffold(body: Text('ORDEN $order'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        codeScannerProvider.overrideWithValue(scanner.call),
        labelResolverProvider.overrideWithValue(
          resolver ?? FakeLabelResolver(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

Finder _scanButton() =>
    findButtonWithText<FilledButton>('Escanear producto');

Future<void> _tapScan(WidgetTester tester) async {
  await tester.tap(_scanButton());
  await tester.pumpAndSettle();
}

void _expectStillOnForm() {
  expect(find.text('Preparar pedido'), findsOneWidget);
  expect(find.textContaining('ORDEN '), findsNothing);
}

void main() {
  testWidgets('QR de un producto abre el pedido del payload (no el JSON)', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([_validQr()]);
    final resolver = FakeLabelResolver();
    final opened = await _pump(tester, scanner, resolver: resolver);

    await _tapScan(tester);

    expect(scanner.requestedTitles, ['Escanear un producto']);
    expect(scanner.requestedFormats.single, kLabelScanFormats);
    expect(find.text('ORDEN DM-260012345'), findsOneWidget);
    expect(opened.toSet(), {'DM-260012345'});
    expect(find.textContaining('{"v"'), findsNothing);
    expect(resolver.requested, isEmpty); // QR: offline, sin /resolve
  });

  testWidgets('Code128 resuelto por el backend abre su pedido', (
    tester,
  ) async {
    final resolver = FakeLabelResolver(
      resolutions: {
        'LBL-01JB8': const LabelResolution(
          labelId: 'LBL-01JB8',
          resolved: true,
          orderNumber: 'DIS-555',
        ),
      },
    );
    await _pump(tester, FakeCodeScanner(['LBL-01JB8']), resolver: resolver);

    await _tapScan(tester);

    expect(resolver.requested, ['LBL-01JB8']);
    expect(find.text('ORDEN DIS-555'), findsOneWidget);
  });

  testWidgets('un número de pedido impreso (no resuelto) abre ese pedido', (
    tester,
  ) async {
    await _pump(tester, FakeCodeScanner(['  DIS-777  ']));

    await _tapScan(tester);

    expect(find.text('ORDEN DIS-777'), findsOneWidget);
  });

  testWidgets('QR dañado: aviso y NO navega', (tester) async {
    final opened = await _pump(
      tester,
      FakeCodeScanner(['{"v":1,"t":"PKG",']),
    );

    await _tapScan(tester);

    _expectStillOnForm();
    expect(opened, isEmpty);
    expect(
      find.text('Esa etiqueta no es de DisTrack o está dañada.'),
      findsOneWidget,
    );
    // El botón vuelve a quedar habilitado para reintentar.
    expect(find.text('Escanear producto'), findsOneWidget);
    expect(
      tester.widget<ButtonStyleButton>(_scanButton()).onPressed,
      isNotNull,
    );
  });

  testWidgets('un código cualquiera: aviso y NO navega', (tester) async {
    final opened = await _pump(tester, FakeCodeScanner(['hola mundo']));

    await _tapScan(tester);

    _expectStillOnForm();
    expect(opened, isEmpty);
    expect(
      find.text(
        'Ese código no es la etiqueta de un producto ni un número de pedido.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('un código en blanco: aviso y NO navega', (tester) async {
    final opened = await _pump(tester, FakeCodeScanner(['   ']));

    await _tapScan(tester);

    _expectStillOnForm();
    expect(opened, isEmpty);
    expect(find.text('No se leyó ningún código.'), findsOneWidget);
  });

  testWidgets('cancelar el escaneo no navega, no avisa ni toca el campo', (
    tester,
  ) async {
    final scanner = FakeCodeScanner([null]);
    final opened = await _pump(tester, scanner);
    await tester.enterText(find.byType(TextField), 'PREVIO');

    await _tapScan(tester);

    expect(scanner.requestedTitles, ['Escanear un producto']);
    _expectStillOnForm();
    expect(opened, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'PREVIO');
  });

  testWidgets('mientras resuelve muestra "Buscando el pedido…" deshabilitado', (
    tester,
  ) async {
    final resolver = _PendingResolver();
    await _pump(tester, FakeCodeScanner(['LBL-9']), resolver: resolver);

    await tester.tap(_scanButton());
    await tester.pump();
    await tester.pump();

    final busy = findButtonWithText<FilledButton>('Buscando el pedido…');
    expect(busy, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(busy).onPressed, isNull);

    resolver.completer.complete(
      const LabelResolution(
        labelId: 'LBL-9',
        resolved: true,
        orderNumber: 'DIS-909',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ORDEN DIS-909'), findsOneWidget);
  });

  testWidgets('al volver del pedido se puede escanear otro', (tester) async {
    final opened = await _pump(
      tester,
      FakeCodeScanner([_validQr(), 'DIS-2']),
    );

    await _tapScan(tester);
    expect(find.text('ORDEN DM-260012345'), findsOneWidget);

    GoRouter.of(tester.element(find.text('ORDEN DM-260012345'))).pop();
    await tester.pumpAndSettle();
    await _tapScan(tester);

    expect(find.text('ORDEN DIS-2'), findsOneWidget);
    expect(opened.toSet(), {'DM-260012345', 'DIS-2'});
  });
}
