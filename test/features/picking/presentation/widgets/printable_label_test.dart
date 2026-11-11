import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emitted_label.dart';
import 'package:logistics_app/features/picking/presentation/widgets/printable_label.dart';

// La etiqueta IMPRESA (papel, impresora de oficina) es minimalista a propósito
// (pedido del dueño: ahorrar papel). Solo pedido, producto, SKU (valor), QR y
// código. Sin "Línea" ni "Destino": quien escanea ve el detalle en la app.

EmittedLabel _label() => const EmittedLabel(
  orderNumber: 'SCZ-261019-01',
  labelId: '01M6P94518T508MZ8XFVYP1JF5',
  keyId: 1,
  sku: 'BAS-QUEEN',
  lineNumber: 1,
  qrContent: '{"id":"01M6P94518T508MZ8XFVYP1JF5"}',
  zpl: '^XA^XZ',
  emittedAt: 1700000000,
  revoked: false,
  productName: 'Base box Queen',
);

Future<void> _pump(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    home: Center(
      child: SizedBox.fromSize(
        size: PrintableLabel.logicalSize,
        child: PrintableLabel(
          label: _label(),
          productName: _label().productName,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('muestra pedido, producto, SKU (valor) y el código', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Pedido SCZ-261019-01'), findsOneWidget);
    expect(find.text('Base box Queen'), findsOneWidget);
    expect(find.text('BAS-QUEEN'), findsOneWidget); // SKU sin la palabra "SKU"
    expect(find.text('01M6P94518T508MZ8XFVYP1JF5'), findsOneWidget);
  });

  testWidgets('NO lleva "Línea", la palabra "SKU" ni la sección "Destino"', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.textContaining('Línea'), findsNothing);
    expect(find.textContaining('SKU '), findsNothing);
    expect(find.text('Destino'), findsNothing);
    expect(find.textContaining('Domicilio'), findsNothing);
  });
}
