import 'package:flutter/material.dart';

import '../../../../core/api/models/emit_label_line.dart';
import 'label_batch_result.dart';
import 'line_draft.dart';
import 'line_editor.dart';

/// Abre el formulario de lote (origen, destino, líneas y, si corresponde, el
/// motivo de reimpresión) y devuelve lo capturado, o null si se cancela.
Future<LabelBatchResult?> showLabelBatchSheet(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required bool requireReason,
  List<EmitLabelLine> initialLines = const [],
}) {
  return showModalBottomSheet<LabelBatchResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => LabelBatchSheet(
      title: title,
      submitLabel: submitLabel,
      requireReason: requireReason,
      initialLines: initialLines,
    ),
  );
}

/// Formulario de emisión/reimpresión de etiquetas: origen, destino, motivo
/// (opcional) y las líneas del pedido.
class LabelBatchSheet extends StatefulWidget {
  const LabelBatchSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.requireReason,
    required this.initialLines,
  });

  final String title;
  final String submitLabel;
  final bool requireReason;
  final List<EmitLabelLine> initialLines;

  @override
  State<LabelBatchSheet> createState() => _LabelBatchSheetState();
}

class _LabelBatchSheetState extends State<LabelBatchSheet> {
  final TextEditingController _origin = TextEditingController();
  final TextEditingController _destination = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final List<LineDraft> _lines;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lines = widget.initialLines.isEmpty
        ? [LineDraft()]
        : widget.initialLines
              .map(
                (l) => LineDraft(
                  sku: l.sku,
                  name: l.name,
                  quantity: l.quantity,
                  pieces: l.piecesPerUnit,
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _reason.dispose();
    _scroll.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() => _lines.add(LineDraft()));
    // Las líneas se arman a demanda: se lleva la vista a la línea nueva para
    // que se vea (y se construya) sin tener que scrollear a mano.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index).dispose();
    });
  }

  void _submit() {
    final origin = _origin.text.trim();
    final destination = _destination.text.trim();
    final reason = _reason.text.trim();
    if (origin.isEmpty || destination.isEmpty) {
      setState(() => _error = 'Indicá el origen y el destino.');
      return;
    }
    if (widget.requireReason && reason.isEmpty) {
      setState(() => _error = 'Indicá el motivo de la reimpresión.');
      return;
    }
    final lines = <EmitLabelLine>[];
    for (final draft in _lines) {
      final sku = draft.sku.text.trim();
      if (sku.isEmpty) continue;
      final quantity = int.tryParse(draft.quantity.text.trim()) ?? 0;
      if (quantity <= 0) {
        setState(
          () => _error = 'La cantidad de cada línea debe ser mayor a 0.',
        );
        return;
      }
      final pieces = int.tryParse(draft.pieces.text.trim()) ?? 1;
      final name = draft.name.text.trim();
      lines.add(
        EmitLabelLine(
          sku: sku,
          name: name.isEmpty ? sku : name,
          quantity: quantity,
          piecesPerUnit: pieces <= 0 ? 1 : pieces,
        ),
      );
    }
    if (lines.isEmpty) {
      setState(() => _error = 'Agregá al menos una línea con SKU y cantidad.');
      return;
    }
    Navigator.of(context).pop(
      LabelBatchResult(
        origin: origin,
        destination: destination,
        lines: lines,
        reason: widget.requireReason ? reason : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    // Líneas perezosas (una reimpresión precarga una línea por SKU, cada una
    // con 4 campos): solo se arman las visibles. El botón de enviar queda
    // fijo abajo, siempre a mano del pulgar.
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: CustomScrollView(
              controller: _scroll,
              shrinkWrap: true,
              slivers: [
                SliverList.list(
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _origin,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Origen',
                        hintText: 'Nodo de origen',
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destination,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Destino',
                        hintText: 'Nodo de destino',
                        prefixIcon: Icon(Icons.place),
                      ),
                    ),
                    if (widget.requireReason) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reason,
                        decoration: const InputDecoration(
                          labelText: 'Motivo de la reimpresión',
                          hintText: 'Ej. etiqueta dañada',
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Líneas (${_lines.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                SliverList.builder(
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final draft = _lines[index];
                    return Padding(
                      // La clave sigue a la línea (no al índice) al quitar una.
                      key: ObjectKey(draft),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LineEditor(
                        draft: draft,
                        index: index,
                        canRemove: _lines.length > 1,
                        onRemove: () => _removeLine(index),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
