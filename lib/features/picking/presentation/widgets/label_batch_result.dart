import '../../../../core/api/models/emit_label_line.dart';

/// Datos capturados en el formulario de emisión/reimpresión de etiquetas.
class LabelBatchResult {
  LabelBatchResult({
    required this.origin,
    required this.destination,
    required this.lines,
    this.reason,
  });

  final String origin;
  final String destination;
  final List<EmitLabelLine> lines;
  final String? reason;
}
