import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/domain/models/carrier_corridor.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/corridor_picker.dart';

import '../../../../support/screen_sizes.dart';
import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';

// Selector de corredor: lista los corredores reales del transportista (de sus
// liquidaciones) con nombres legibles y, si no hay ninguno, degrada a entrada
// manual explicando por qué.

/// Lo último que el selector informó al formulario.
class _Picked {
  CarrierCorridor? value;
}

Future<_Picked> _pump(
  WidgetTester tester, {
  String? carrierId = 'c1',
  Future<List<Settlement>> Function(String carrierId)? onListSettlements,
  bool textScale = false,
}) async {
  final picked = _Picked();
  final listSettlements =
      onListSettlements ?? ((_) async => const <Settlement>[]);
  final picker = CorridorPicker(
    carrierId: carrierId,
    onChanged: (corridor) => picked.value = corridor,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        carrierRepositoryProvider.overrideWithValue(
          FakeCarrierRepository(onListSettlements: listSettlements),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: textScale ? withTextScale(picker) : picker,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  testWidgets('con un solo corredor lo deja elegido sin pedir nada', (
    tester,
  ) async {
    final picked = await _pump(
      tester,
      onListSettlements: (_) async => [
        settlement(
          corridorFrom: 'cd-santa-cruz',
          corridorTo: 'store-scz-centro',
          corridorType: CorridorType.cdToStore,
        ),
      ],
    );

    // Nombre legible, nunca la clave cruda del backend.
    expect(find.text('CD Santa Cruz → Tienda SCZ Centro'), findsOneWidget);
    expect(find.text('cd-santa-cruz'), findsNothing);
    expect(find.text('Tipo: CD → Tienda'), findsOneWidget);
    expect(
      picked.value,
      const CarrierCorridor(
        from: 'cd-santa-cruz',
        to: 'store-scz-centro',
        type: CorridorType.cdToStore,
      ),
    );
  });

  testWidgets('con varios corredores pide elegir y al elegir informa el par '
      'completo y su tipo', (tester) async {
    final picked = await _pump(
      tester,
      onListSettlements: (_) async => [
        settlement(
          corridorFrom: 'cd-la-paz',
          corridorTo: 'cd-santa-cruz',
          corridorType: CorridorType.cdToCd,
        ),
        settlement(
          id: 's2',
          corridorFrom: 'cd-santa-cruz',
          corridorTo: 'store-scz-centro',
          corridorType: CorridorType.cdToStore,
        ),
      ],
    );

    expect(find.text('Elegí tu corredor'), findsOneWidget);
    expect(picked.value, isNull);

    await tester.tap(find.text('Elegí tu corredor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CD Santa Cruz → Tienda SCZ Centro').last);
    await tester.pumpAndSettle();

    expect(
      picked.value,
      const CarrierCorridor(
        from: 'cd-santa-cruz',
        to: 'store-scz-centro',
        type: CorridorType.cdToStore,
      ),
    );
    expect(find.text('Tipo: CD → Tienda'), findsOneWidget);
    expect(find.text('Elegí tu corredor'), findsNothing);
  });

  testWidgets('sin liquidaciones ofrece entrada manual y explica por qué', (
    tester,
  ) async {
    final picked = await _pump(tester);

    expect(
      find.textContaining('Todavía no tenemos corredores tuyos'),
      findsOneWidget,
    );
    expect(find.text('Elegí tu corredor'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Origen'),
      'CD-Santa-Cruz',
    );
    expect(picked.value, isNull, reason: 'falta el destino');

    await tester.enterText(
      find.widgetWithText(TextField, 'Destino'),
      'store-scz-centro',
    );
    await tester.pumpAndSettle();

    // Se normaliza a minúsculas: el backend espera la clave tal cual.
    expect(
      picked.value,
      const CarrierCorridor(
        from: 'cd-santa-cruz',
        to: 'store-scz-centro',
        type: CorridorType.cdToStore,
      ),
    );
  });

  testWidgets('en manual el tipo de corredor es un selector, no texto libre', (
    tester,
  ) async {
    final picked = await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Origen'),
      'cd-santa-cruz',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino'),
      'cd-cochabamba',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CD → Tienda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CD → CD').last);
    await tester.pumpAndSettle();

    expect(picked.value?.type, CorridorType.cdToCd);
  });

  testWidgets('si falla traer los corredores no bloquea: entrada manual', (
    tester,
  ) async {
    await _pump(
      tester,
      onListSettlements: (_) async =>
          throw const ApiException(status: 500, title: 'x', detail: 'Falló'),
    );

    expect(
      find.textContaining('No pudimos traer tus corredores'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Origen'), findsOneWidget);
  });

  testWidgets('sin transportista elegido avisa y permite escribirlo', (
    tester,
  ) async {
    await _pump(tester, carrierId: null);

    expect(find.textContaining('Elegí tu transportista'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Destino'), findsOneWidget);
  });

  testOnScreens('corredores largos no desbordan con letra grande', (
    tester,
    screen,
  ) async {
    await _pump(
      tester,
      textScale: true,
      onListSettlements: (_) async => [
        settlement(
          corridorFrom: 'cd-santa-cruz-de-la-sierra',
          corridorTo: 'store-scz-norte-equipetrol',
          corridorType: CorridorType.cdToStore,
        ),
        settlement(
          id: 's2',
          corridorFrom: 'cd-cochabamba',
          corridorTo: 'store-cbb-centro',
          corridorType: CorridorType.cdToStore,
        ),
      ],
    );

    expect(find.text('Elegí tu corredor'), findsOneWidget);
  });
}
