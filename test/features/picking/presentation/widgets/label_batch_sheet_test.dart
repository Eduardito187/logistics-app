import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emit_label_line.dart';
import 'package:logistics_app/features/picking/presentation/widgets/label_batch_result.dart';
import 'package:logistics_app/features/picking/presentation/widgets/label_batch_sheet.dart';
import 'package:logistics_app/features/picking/presentation/widgets/line_editor.dart';

// Formulario (bottom sheet) de emisión/reimpresión de etiquetas. Valida origen,
// destino, motivo (si se exige) y las líneas; devuelve un LabelBatchResult.

/// Campos de texto dentro del sheet (origen, destino, [motivo], y por línea
/// sku/nombre/cantidad/piezas).
Finder _sheetFields() => find.descendant(
  of: find.byType(LabelBatchSheet),
  matching: find.byType(TextField),
);

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.descendant(
    of: find.byType(LabelBatchSheet),
    matching: find.widgetWithText(FilledButton, 'Emitir'),
  );
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  List<Object?> box, {
  bool requireReason = false,
  List<EmitLabelLine> initialLines = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              box[0] = await showLabelBatchSheet(
                context,
                title: 'Emitir etiquetas',
                submitLabel: 'Emitir',
                requireReason: requireReason,
                initialLines: initialLines,
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con una línea válida devuelve el resultado capturado', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    final fields = _sheetFields();
    await tester.enterText(fields.at(0), 'LPZ'); // origen
    await tester.enterText(fields.at(1), 'SCZ'); // destino
    await tester.enterText(fields.at(2), 'SKU-9'); // sku de la línea
    await tester.enterText(fields.at(4), '3'); // cantidad
    await _tapSubmit(tester);

    final result = box[0] as LabelBatchResult;
    expect(result.origin, 'LPZ');
    expect(result.destination, 'SCZ');
    expect(result.lines, hasLength(1));
    expect(result.lines.single.sku, 'SKU-9');
    expect(result.lines.single.quantity, 3);
    // Sin nombre, se usa el SKU como nombre.
    expect(result.lines.single.name, 'SKU-9');
    expect(result.reason, isNull); // no se exigía motivo
  });

  testWidgets('falta origen/destino → error y no cierra', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.enterText(_sheetFields().at(2), 'SKU-1');
    await _tapSubmit(tester);

    expect(find.text('Indicá el origen y el destino.'), findsOneWidget);
    expect(box[0], #pending); // sigue abierto, sin resultado
  });

  testWidgets('cantidad <= 0 muestra el error de cantidad', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.enterText(_sheetFields().at(0), 'LPZ');
    await tester.enterText(_sheetFields().at(1), 'SCZ');
    await tester.enterText(_sheetFields().at(2), 'SKU-1');
    await tester.enterText(_sheetFields().at(4), '0'); // cantidad inválida
    await _tapSubmit(tester);

    expect(
      find.text('La cantidad de cada línea debe ser mayor a 0.'),
      findsOneWidget,
    );
    expect(box[0], #pending);
  });

  testWidgets('sin ninguna línea con SKU muestra su error', (tester) async {
    final box = <Object?>[#pending];
    await _open(tester, box);

    await tester.enterText(_sheetFields().at(0), 'LPZ');
    await tester.enterText(_sheetFields().at(1), 'SCZ');
    // El SKU queda vacío → la línea se ignora → no hay líneas.
    await _tapSubmit(tester);

    expect(
      find.text('Agregá al menos una línea con SKU y cantidad.'),
      findsOneWidget,
    );
    expect(box[0], #pending);
  });

  testWidgets(
    'requireReason: sin motivo da error; con motivo devuelve reason',
    (tester) async {
      final box = <Object?>[#pending];
      await _open(tester, box, requireReason: true);

      // Con motivo, el orden de campos es: origen(0), destino(1), motivo(2),
      // luego la línea: sku(3), nombre(4), cantidad(5), piezas(6).
      await tester.enterText(_sheetFields().at(0), 'LPZ');
      await tester.enterText(_sheetFields().at(1), 'SCZ');
      await tester.enterText(_sheetFields().at(3), 'SKU-1');
      await _tapSubmit(tester);

      expect(find.text('Indicá el motivo de la reimpresión.'), findsOneWidget);
      expect(box[0], #pending);

      // Ahora sí, con motivo.
      await tester.enterText(_sheetFields().at(2), 'etiqueta dañada');
      await _tapSubmit(tester);

      final result = box[0] as LabelBatchResult;
      expect(result.reason, 'etiqueta dañada');
    },
  );

  testWidgets('precarga las líneas iniciales y permite agregar/quitar', (
    tester,
  ) async {
    final box = <Object?>[#pending];
    await _open(
      tester,
      box,
      initialLines: const [
        EmitLabelLine(sku: 'SKU-A', name: 'Taladro', quantity: 2),
      ],
    );

    // Arranca con una línea (la inicial), sin botón de quitar (canRemove=false).
    expect(find.byType(LineEditor), findsOneWidget);
    expect(find.text('Líneas (1)'), findsOneWidget);
    expect(find.text('SKU-A'), findsOneWidget);

    // Agregar una segunda línea.
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.byType(LineEditor), findsNWidgets(2));
    expect(find.text('Líneas (2)'), findsOneWidget);

    // Ahora cada línea puede quitarse: quitamos una.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.byType(LineEditor), findsOneWidget);
  });
}
