import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/models/device_list_item.dart';
import 'package:logistics_app/features/settings/presentation/widgets/device_card.dart';

// Tarjeta de un dispositivo/sesión: nombre, plataforma, última actividad, uuid y
// acción de revocar. Marca el actual y los revocados. Usa device_format (es).

DeviceListItem _device({
  String? name = 'Zebra TC',
  String? platform = 'android',
  bool revoked = false,
}) => DeviceListItem(
  uuid: 'uuid-abc-123',
  platform: platform,
  name: name,
  lastSeenAt: DateTime(2026, 3, 5, 14, 30),
  revoked: revoked,
);

Future<void> _pump(
  WidgetTester tester, {
  required DeviceListItem device,
  required bool isCurrent,
  VoidCallback? onRevoke,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DeviceCard(
          device: device,
          isCurrent: isCurrent,
          onRevoke: onRevoke,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('muestra nombre, plataforma, uuid y última actividad', (
    tester,
  ) async {
    await _pump(tester, device: _device(), isCurrent: false, onRevoke: () {});

    expect(find.text('Zebra TC'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
    expect(find.text('uuid-abc-123'), findsOneWidget);
    expect(find.textContaining('Última actividad:'), findsOneWidget);
  });

  testWidgets('sin nombre cae a la etiqueta de plataforma', (tester) async {
    await _pump(
      tester,
      device: _device(name: null, platform: 'ios'),
      isCurrent: false,
      onRevoke: () {},
    );

    // El título usa platformLabel('ios') = 'iOS'.
    expect(find.text('iOS'), findsWidgets);
  });

  testWidgets('nombre vacío también cae a la plataforma', (tester) async {
    await _pump(
      tester,
      device: _device(name: '  '),
      isCurrent: false,
      onRevoke: () {},
    );

    expect(find.text('Android'), findsWidgets);
  });

  testWidgets('el modelo del equipo se muestra junto a "Este teléfono"', (
    tester,
  ) async {
    // Lo que resuelve el problema real: con tres teléfonos registrados, el
    // usuario ve el modelo de cada uno y cuál es el que tiene en la mano.
    await _pump(
      tester,
      device: _device(name: 'OnePlus CPH2749'),
      isCurrent: true,
      onRevoke: () {},
    );

    expect(find.text('OnePlus CPH2749'), findsOneWidget);
    expect(find.text('Este teléfono'), findsOneWidget);
  });

  testWidgets('dispositivo actual: muestra la pastilla y el botón específico', (
    tester,
  ) async {
    await _pump(tester, device: _device(), isCurrent: true, onRevoke: () {});

    expect(find.text('Este teléfono'), findsOneWidget);
    expect(find.text('Revocar este dispositivo'), findsOneWidget);
  });

  testWidgets('otro dispositivo: botón "Revocar sesión"', (tester) async {
    await _pump(tester, device: _device(), isCurrent: false, onRevoke: () {});

    expect(find.text('Revocar sesión'), findsOneWidget);
  });

  testWidgets('dispositivo revocado (no actual): muestra la pastilla', (
    tester,
  ) async {
    await _pump(
      tester,
      device: _device(revoked: true),
      isCurrent: false,
      onRevoke: null,
    );

    expect(find.text('Revocado'), findsOneWidget);
  });

  testWidgets('sin onRevoke no muestra botón de revocar', (tester) async {
    await _pump(tester, device: _device(), isCurrent: false, onRevoke: null);

    expect(find.text('Revocar sesión'), findsNothing);
    expect(find.text('Revocar este dispositivo'), findsNothing);
  });

  testWidgets('tocar revocar dispara el callback', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      device: _device(),
      isCurrent: false,
      onRevoke: () => tapped = true,
    );

    await tester.tap(find.text('Revocar sesión'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
