import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/layout/adaptive_card_rows.dart';

import '../../support/screen_sizes.dart';

/// Tarjeta de prueba: alto variable según el índice (simula letra grande).
Widget _card(BuildContext context, int index) => Container(
  key: ValueKey('card-$index'),
  height: 60.0 + (index % 3) * 40,
  color: const Color(0xFF2196F3),
  child: Text('Tarjeta $index'),
);

Widget _sliverHost(Widget sliver) => MaterialApp(
  home: Scaffold(body: CustomScrollView(slivers: [sliver])),
);

Widget _boxHost(Widget child) => MaterialApp(home: Scaffold(body: child));

int _expectedColumns(TestScreen screen, {int maxColumns = 3}) {
  final width = screen.size.width;
  if (width >= 840) return maxColumns < 3 ? maxColumns : 3;
  if (width >= 600) return maxColumns < 2 ? maxColumns : 2;
  return 1;
}

/// Cuenta cuántas tarjetas comparten la coordenada Y de la primera.
int _cardsInFirstRow(WidgetTester tester) {
  final y = tester.getTopLeft(find.byKey(const ValueKey('card-0'))).dy;
  var count = 0;
  for (var i = 0; i < 3; i++) {
    final finder = find.byKey(ValueKey('card-$i'));
    if (finder.evaluate().isEmpty) break;
    if (tester.getTopLeft(finder).dy == y) count++;
  }
  return count;
}

void main() {
  group('adaptiveColumnsFor', () {
    test('respeta los puntos de corte y el tope', () {
      expect(adaptiveColumnsFor(320), 1);
      expect(adaptiveColumnsFor(700), 2);
      expect(adaptiveColumnsFor(1000), 3);
      expect(adaptiveColumnsFor(1000, maxColumns: 2), 2);
      expect(adaptiveColumnsFor(1000, maxColumns: 0), 1);
    });
  });

  group('SliverAdaptiveCardRows', () {
    testOnScreens('reparte en columnas según el ancho sin desbordes', (
      tester,
      screen,
    ) async {
      await tester.pumpWidget(
        withTextScale(
          _sliverHost(
            const SliverAdaptiveCardRows(itemCount: 7, itemBuilder: _card),
          ),
        ),
      );
      expect(_cardsInFirstRow(tester), _expectedColumns(screen));
      expect(tester.takeException(), isNull);
    });

    testOnScreens('maxColumns limita las columnas', (tester, screen) async {
      await tester.pumpWidget(
        _sliverHost(
          const SliverAdaptiveCardRows(
            itemCount: 5,
            maxColumns: 2,
            itemBuilder: _card,
          ),
        ),
      );
      expect(_cardsInFirstRow(tester), _expectedColumns(screen, maxColumns: 2));
    });

    testWidgets('la fila toma el alto de la tarjeta más alta', (tester) async {
      useScreen(tester, TestScreen.tabletLandscape);
      await tester.pumpWidget(
        _sliverHost(
          const SliverAdaptiveCardRows(
            itemCount: 4,
            spacing: 10,
            itemBuilder: _card,
          ),
        ),
      );
      // Fila 0: alturas 60/100/140 → la fila 1 arranca en 140 + 10.
      final top0 = tester.getTopLeft(find.byKey(const ValueKey('card-0'))).dy;
      final top3 = tester.getTopLeft(find.byKey(const ValueKey('card-3'))).dy;
      expect(top3 - top0, 150);
      // Alineadas arriba: la tarjeta baja no se estira.
      expect(tester.getSize(find.byKey(const ValueKey('card-0'))).height, 60);
    });

    testWidgets('construye perezosamente (solo lo visible)', (tester) async {
      useScreen(tester, TestScreen.phone);
      await tester.pumpWidget(
        _sliverHost(
          const SliverAdaptiveCardRows(itemCount: 500, itemBuilder: _card),
        ),
      );
      expect(find.byKey(const ValueKey('card-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('card-499')), findsNothing);
    });

    testWidgets('lista vacía no rompe', (tester) async {
      await tester.pumpWidget(
        _sliverHost(
          const SliverAdaptiveCardRows(itemCount: 0, itemBuilder: _card),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AdaptiveCardRows', () {
    testOnScreens('reparte en columnas según el ancho sin desbordes', (
      tester,
      screen,
    ) async {
      await tester.pumpWidget(
        withTextScale(
          _boxHost(const AdaptiveCardRows(itemCount: 7, itemBuilder: _card)),
        ),
      );
      expect(_cardsInFirstRow(tester), _expectedColumns(screen));
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aplica padding y espaciado entre columnas', (tester) async {
      useScreen(tester, TestScreen.tabletLandscape);
      await tester.pumpWidget(
        _boxHost(
          const AdaptiveCardRows(
            itemCount: 3,
            padding: EdgeInsets.all(20),
            columnSpacing: 8,
            itemBuilder: _card,
          ),
        ),
      );
      final first = tester.getTopLeft(find.byKey(const ValueKey('card-0')));
      expect(first, const Offset(20, 20));
      final firstRight = tester
          .getTopRight(find.byKey(const ValueKey('card-0')))
          .dx;
      final secondLeft = tester
          .getTopLeft(find.byKey(const ValueKey('card-1')))
          .dx;
      expect(secondLeft - firstRight, 8);
    });

    testWidgets('construye perezosamente (solo lo visible)', (tester) async {
      useScreen(tester, TestScreen.smallPhone);
      await tester.pumpWidget(
        _boxHost(const AdaptiveCardRows(itemCount: 500, itemBuilder: _card)),
      );
      expect(find.byKey(const ValueKey('card-499')), findsNothing);
    });
  });
}
