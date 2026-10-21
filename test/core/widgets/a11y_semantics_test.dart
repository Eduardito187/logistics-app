import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/theme/app_colors.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/widgets/async_value_view.dart';
import 'package:logistics_app/core/widgets/empty_state.dart';
import 'package:logistics_app/core/widgets/section_card.dart';
import 'package:logistics_app/core/widgets/stat_tile.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';

// Lectores de pantalla en los widgets compartidos: pastilla "Estado: X",
// métrica "etiqueta: valor" en un nodo, títulos como encabezados, ícono
// decorativo excluido y spinner con etiqueta. Más el aspecto en alto contraste.

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('StatusPill se anuncia como "Estado: etiqueta"', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const StatusPill('En ruta', tone: PillTone.info));
    expect(find.bySemanticsLabel('Estado: En ruta'), findsOneWidget);
    await _pump(
      tester,
      const StatusPill('Listo', semanticsLabel: 'Pedido listo'),
    );
    expect(find.bySemanticsLabel('Pedido listo'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('StatTile es un solo nodo "etiqueta: valor"', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const StatTile(value: '12', label: 'Entregas'));
    expect(find.bySemanticsLabel('Entregas: 12'), findsOneWidget);
    // El número suelto no es un nodo aparte.
    expect(find.bySemanticsLabel('12'), findsNothing);
    handle.dispose();
  });

  testWidgets('SectionCard y EmptyState marcan su título como encabezado', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionCard(title: 'Impresora', child: Text('Zebra')),
          EmptyState(icon: Icons.inbox, title: 'Sin pedidos'),
        ],
      ),
    );
    for (final title in ['Impresora', 'Sin pedidos']) {
      expect(
        tester.getSemantics(find.text(title)),
        matchesSemantics(label: title, isHeader: true),
      );
    }
    handle.dispose();
  });

  testWidgets('LoadingView anuncia "Cargando"', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const LoadingView());
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'StatusPill en alto contraste: fondo blanco, borde y tinta oscura',
    (tester) async {
      await _pump(
        tester,
        const StatusPill('Atrasado', tone: PillTone.warning),
        theme: AppTheme.highContrast(),
      );
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusPill),
          matching: find.byType(Container),
        ),
      );
      final deco = box.decoration! as BoxDecoration;
      expect(deco.color, Colors.white);
      expect((deco.border! as Border).top.width, 2);
      final text = tester.widget<Text>(find.text('Atrasado'));
      expect(text.style?.color, AppColors.hcWarning);
    },
  );

  testWidgets('StatTile en alto contraste usa el semántico oscuro', (
    tester,
  ) async {
    await _pump(
      tester,
      const StatTile(value: '3', label: 'Fallidas', color: AppColors.danger),
      theme: AppTheme.highContrast(),
    );
    final text = tester.widget<Text>(find.text('3'));
    expect(text.style?.color, AppColors.hcDanger);
  });
}
